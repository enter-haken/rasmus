SET search_path TO core,public;

-- the request must contain at least the following keys: 
-- schema 
-- entity
-- payload
-- action

CREATE FUNCTION send_transfer_message() RETURNS TRIGGER AS $$
BEGIN 
    PERFORM core.send_message(NEW.id, NEW.state, NEW.request, NEW.result);
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER send_receipt_trigger BEFORE INSERT ON transfer
    FOR EACH ROW EXECUTE PROCEDURE send_transfer_message();

CREATE TRIGGER got_response_trigger AFTER UPDATE ON transfer
    FOR EACH ROW EXECUTE PROCEDURE send_transfer_message();


-- after a row is inserted into the `transfer` table
-- the `transfer_manager` is called from the backend.
-- here comes the heavy lifting
CREATE FUNCTION transfer_manager(transfer_id TEXT) RETURNS VOID AS $$
DECLARE
    transfer_record RECORD;
BEGIN
    SELECT id, state, request, result FROM core.transfer WHERE id = transfer_id::UUID INTO transfer_record;

    PERFORM core.set_succeeded(transfer_record.id);
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

