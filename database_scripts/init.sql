CREATE SCHEMA rasmus;

SET search_path TO rasmus,public;

-- this is needed for gen_random_uuid();
-- the gen_random_uuid function will be created in the first schema
-- wich appears in the search path
-- the default is the public schema 
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE LANGUAGE  plpython3u;

-- when postgres is compiled with python support
-- CREATE OR REPLACE LANGUAGE plpython3u;

CREATE TYPE transfer_state as ENUM (
    'pending',
    'processing',
    'succeeded',
    'succeeded_with_warning',
    'error'
);

CREATE TYPE role_level AS ENUM ('admin','user');

-- this is the json_view base document
CREATE FUNCTION get_entity(entity TEXT) RETURNS JSONB AS $$
BEGIN
    RETURN format('{ "entity": "%s", "is_dirty": false }', entity)::JSONB;
END
$$ LANGUAGE plpgsql;


