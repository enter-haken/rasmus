SET search_path TO core,public;

-- send a message to the backend, if a record is set to dirty
-- the raw_entity_record must contain a json_view
CREATE FUNCTION send_dirty_message(id UUID, schema TEXT, entity TEXT) RETURNS VOID AS $$
DECLARE 
    message_response JSONB;
BEGIN
    -- get an unescaped version of a json string
    message_response := '[]' || (
        jsonb_build_object('id', id) ||
        jsonb_build_object('action', 'set_dirty') ||
        jsonb_build_object('entity', entity)
    );

    PERFORM pg_notify(schema, message_response->>0);
END
$$ LANGUAGE plpgsql;

-- send a message to the backend, when a new record is inserted into transfer
CREATE FUNCTION send_message(id UUID, state transfer_state, request JSONB, response JSONB) RETURNS VOID AS $$
DECLARE 
    message_response JSONB;
BEGIN
    -- get an unescaped version of a json string
    message_response := '[]' || (
        jsonb_build_object('id', id) ||
        jsonb_build_object('state', state) ||
        jsonb_build_object('action', request->>'action') ||
        jsonb_build_object('entity', request->>'entity')
    );

    PERFORM pg_notify(request->>'schema', message_response->>0);
END
$$ LANGUAGE plpgsql;
