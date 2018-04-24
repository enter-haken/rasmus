SET search_path TO core,public;

CREATE TYPE transfer_state as ENUM (
    'pending',
    'processing',
    'ready',
    'succeeded',
    'succeeded_with_warning',
    'error'
);

-- the request must contain at least the following keys: 
-- schema 
-- entity
-- payload
-- action

CREATE TABLE transfer(
	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    state transfer_state NOT NULL DEFAULT 'pending',
    request JSONB NOT NULL,
    result JSONB
);

CREATE FUNCTION send_receipt() RETURNS TRIGGER AS $$
BEGIN 
    --todo: make some base validation on the request object
    -- eg. valid schema / entity / action
    -- payload not null
    -- ...

    -- each schema has it's own listener channel
    PERFORM pg_notify(NEW.request->>'schema', NEW.id::text);
    -- actions could be launched here, but the trigger should return quickly
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- usually inserts are requests from the web backend
CREATE TRIGGER send_receipt_trigger BEFORE INSERT ON transfer
    FOR EACH ROW EXECUTE PROCEDURE send_receipt();


--CREATE FUNCTION process_receipt(transfer_id UUID) RETURNS VOID AS $$
--
--$$ LANGUAGE plpgsql;






-- update transfer states
CREATE FUNCTION set_state(transfer_id UUID, new_state transfer_state) RETURNS VOID AS $$
BEGIN
    UPDATE transfer set state = new_state WHERE id = transfer_id;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_pending(transfer_id UUID) RETURNS VOID AS $$
BEGIN
    PERFORM set_state(transfer_id, 'pending');
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_processing(transfer_id UUID) RETURNS VOID AS $$
BEGIN
    PERFORM set_state(transfer_id, 'processing'); 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_succeeded(transfer_id UUID) RETURNS VOID AS $$
BEGIN
    PERFORM set_state(transfer_id, 'succeeded'); 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_succeded_with_warning(transfer_id UUID) RETURNS VOID AS $$
BEGIN
    PERFORM set_state(transfer_id, 'succeeded_with_warning'); 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_error(transfer_id UUID) RETURNS VOID AS $$
BEGIN
    PERFORM set_state(transfer_id, 'error'); 
END
$$ LANGUAGE plpgsql;


-- after processing is finishesd handle notifications
-- based on the state
-- a worker function must not send notifications to the backend
CREATE FUNCTION finished() RETURNS TRIGGER AS $$
BEGIN
    NEW.state = 'succeeded';
    --todo: notify backend -> schema, entity, transfer id
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

