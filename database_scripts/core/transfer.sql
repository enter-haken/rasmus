SET search_path TO core,public;

-- this is the entry point to the database

-- request:
-- {
--     "action": "add",
--     "schema": "core",
--     "entity": "privilege",
--     "data": {
--         "name": "dasboard",
--         "description": "show dashboard",
--         "role_level": "guest"
--     }
-- }

-- action: 
-- * 'pending' -> initial value
-- * 'processing', -> the coresponding manager does it's work
-- * 'succeeded',
-- * 'succeeded_with_warning',
-- * 'error'

-- entity:
-- * `role`
-- * `privilege`
-- * `user_account`

-- schema:
-- * `core` -> the current schema for the operation

-- data:
-- * json object -> single result
-- * json array -> multiple result
-- * empty -> the data object is empty, when there was an error

-- todo: what about error state?
CREATE TABLE transfer(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    state transfer_state NOT NULL DEFAULT 'pending',
    request JSONB NOT NULL,
    response JSONB
);

CREATE FUNCTION send_transfer_message() RETURNS TRIGGER AS $$
BEGIN 
    --todo: declare, when a message should be send to the backend?
    PERFORM core.send_message(NEW.id, NEW.state, NEW.request, NEW.response);
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- sends a receipt message to the counter after a new request is inserted
CREATE TRIGGER send_receipt_trigger BEFORE INSERT ON transfer
    FOR EACH ROW EXECUTE PROCEDURE send_transfer_message();

-- sends a receipt message to the counter after a request is updated
-- only a state change will trigger a message
CREATE TRIGGER got_response_trigger AFTER UPDATE ON transfer
    FOR EACH ROW 
    WHEN (OLD.state IS DISTINCT FROM NEW.state)
        EXECUTE PROCEDURE send_transfer_message();

-- the `transfer_manager` chooses the corresponding entity manager for further processing
-- if no exception is risen the backend sets the state to `succeeded`.
-- if an exception is risen, the backend sets the state to `error`
CREATE FUNCTION transfer_manager(transfer_id TEXT) RETURNS VOID AS $$
DECLARE
    transfer_record RECORD;
    transfer_response JSONB;
BEGIN
   SELECT id, state, request, response FROM core.transfer WHERE id = transfer_id::UUID INTO transfer_record;

   CASE transfer_record.request->>'entity'
       WHEN 'role' THEN 
           BEGIN
                RAISE EXCEPTION 'role manager missing for id %', transfer_record.id;
           END;
       WHEN 'privilege' THEN 
           BEGIN
               SELECT core.privilege_manager(transfer_record.request) INTO transfer_response;
               RAISE NOTICE 'privilege manager response: %', transfer_response;
               RAISE WARNING 'WARNING';
               PERFORM core.set_response(transfer_id::UUID, transfer_response);
           END;
       WHEN 'user_account' THEN 
           BEGIN 
               RAISE EXCEPTION 'user_account manager missing';
           END;
       ELSE 
           BEGIN
               RAISE EXCEPTION 'entity `%` unknown', transfer_record.request->>'entity' 
                   USING HINT = 'entity must one of role, privilege or user_account';
           END;
   END CASE;

   RAISE NOTICE '% updated', transfer_record.request->>'entity';
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_response(transfer_id UUID, transfer_response JSONB) RETURNS VOID AS $$
BEGIN
    UPDATE core.transfer SET response = transfer_response WHERE id = transfer_id;
END
$$ LANGUAGE plpgsql;

-- update transfer states
CREATE FUNCTION set_state(transfer_id UUID, new_state transfer_state) RETURNS VOID AS $$
BEGIN
    UPDATE core.transfer set state = new_state WHERE id = transfer_id;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_pending(transfer_id TEXT) RETURNS VOID AS $$
BEGIN
    PERFORM core.set_state(transfer_id::UUID, 'pending');
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_processing(transfer_id TEXT) RETURNS VOID AS $$
BEGIN
 
    PERFORM core.set_state(transfer_id::UUID, 'processing'); 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_succeeded(transfer_id TEXT) RETURNS VOID AS $$
BEGIN
    PERFORM core.set_state(transfer_id::UUID, 'succeeded'); 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_succeeded_with_warning(transfer_id TEXT) RETURNS VOID AS $$
BEGIN
    PERFORM core.set_state(transfer_id::UUID, 'succeeded_with_warning'); 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_error(transfer_id TEXT) RETURNS VOID AS $$
BEGIN
    PERFORM core.set_state(transfer_id::UUID, 'error'); 
END
$$ LANGUAGE plpgsql;
