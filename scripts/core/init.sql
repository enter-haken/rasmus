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
    RETURN format('{ "entity": "%s", "is_dirty": false}', entity)::JSONB;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION send_message(schema TEXT, entity TEXT, action TEXT, message TEXT) RETURNS VOID AS $$
BEGIN
    PERFORM pg_notify(schema, format('{"schema":"%s","entity":"%s","action":"%s" "message":"%s"}', schema, entity, action, message));
END
$$ LANGUAGE plpgsql;
