CREATE SCHEMA core;

SET search_path TO core,public;

-- this is needed for gen_random_uuid();
-- the gen_random_uuid function will be created in the first schema
-- wich appears in the search path
-- the default is the public schema 
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- when postgres is compiled with python support
-- CREATE OR REPLACE LANGUAGE plpython3u;

CREATE FUNCTION get_entity(entity TEXT) RETURNS JSONB AS $$
BEGIN
    --todo: use jsonb_build_object
    RETURN format('{ "entity": "%s", "is_dirty": false, "schema":"core"}', entity)::JSONB;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION send_message(raw_transfer_row ANYELEMENT) RETURNS VOID AS $$
DECLARE 
    message_response JSONB;
    transfer_row RECORD;
BEGIN
    transfer_row := raw_transfer_row::RECORD;
    -- get an unescaped version of a json string
    message_response := '[]' || (
        jsonb_build_object('id', transfer_row.id) ||
        jsonb_build_object('state', transfer_row.state) ||
        jsonb_build_object('action', transfer_row.request->>'action') ||
        jsonb_build_object('entity', transfer_row.request->>'entity')
    );

    RAISE NOTICE '%', message_response;

    PERFORM pg_notify(transfer_row.request->>'schema', message_response->>0);

END
$$ LANGUAGE plpgsql;

CREATE FUNCTION send_dirty_message(raw_entity_record ANYELEMENT) RETURNS VOID AS $$
DECLARE 
    message_response JSONB;
    entity_record RECORD;
BEGIN
    entity_record := raw_entity_record::RECORD;
    -- get an unescaped version of a json string
    message_response := '[]' || (
        jsonb_build_object('id', entity_record.id) ||
        jsonb_build_object('action', 'set_dirty') ||
        jsonb_build_object('entity', entity_record.json_view->>'entity')
    );

    RAISE NOTICE 'set dirty: %', message_response;

    PERFORM pg_notify(entity_record.json_view->>'schema', message_response->>0);
END

$$ LANGUAGE plpgsql;

