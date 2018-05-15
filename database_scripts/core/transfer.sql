SET search_path TO core,public;

-- this is the entry point to the database
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


-- after a row is inserted into the `transfer` table
-- a message is send to the backend. 
-- the `transfer_manager` is called by the backend.
-- this approach should lead to fast inserts into the `transfer` table 

-- here comes the heavy lifting
CREATE FUNCTION transfer_manager(transfer_id TEXT) RETURNS VOID AS $$
DECLARE
    transfer_record RECORD;
    transfer_response JSONB;
BEGIN
    SELECT id, state, request, response FROM core.transfer WHERE id = transfer_id::UUID INTO transfer_record;
    
    --BEGIN
        CASE transfer_record.request->>'entity'
            WHEN 'role' THEN RAISE EXCEPTION 'role manager missing';
            WHEN 'privilege' THEN 
                BEGIN
                    SELECT core.privilege_manager(transfer_record.request) INTO transfer_response;
                    RAISE NOTICE 'privilege manager response: %', transfer_response;
                    PERFORM core.set_response(transfer_id::UUID, transfer_response);
                END;
            WHEN 'user_account' THEN RAISE EXCEPTION 'user_account manager missing';
            ELSE RAISE EXCEPTION 'entity `%` unknown', transfer_record.request->>'entity' 
                USING HINT = 'entity must one of role, privilege or user_account';
        END CASE;
    --EXCEPTION
    --    WHEN OTHERS THEN 
    --        PERFORM set_error(transfer_id::UUID);

    -- after the manager has succeeded the transfer record can be set to `succeed`
    PERFORM core.set_succeeded(transfer_record.id);
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

CREATE FUNCTION set_pending(transfer_id UUID) RETURNS VOID AS $$
BEGIN
    PERFORM core.set_state(transfer_id, 'pending');
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_processing(transfer_id UUID) RETURNS VOID AS $$
BEGIN
 
    PERFORM core.set_state(transfer_id, 'processing'); 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_succeeded(transfer_id UUID) RETURNS VOID AS $$
BEGIN
    PERFORM core.set_state(transfer_id, 'succeeded'); 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_succeded_with_warning(transfer_id UUID) RETURNS VOID AS $$
BEGIN
    PERFORM core.set_state(transfer_id, 'succeeded_with_warning'); 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_error(transfer_id UUID) RETURNS VOID AS $$
BEGIN
    PERFORM core.set_state(transfer_id, 'error'); 
END
$$ LANGUAGE plpgsql;


-- after processing is finishesd handle notifications
-- based on the state
-- a worker function must not send notifications to the backend
CREATE FUNCTION finished() RETURNS TRIGGER AS $$
BEGIN
    NEW.state = 'succeeded';
    --todo: notify backend -> schema, entity, transfer id, status
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

