CREATE SCHEMA core;

SET search_path TO core,public;

-- this is needed for gen_random_uuid();
-- the gen_random_uuid function will be created in the first schema
-- wich appears in the search path
-- the default is the public schema 
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- when postgres is compiled with python support
-- CREATE OR REPLACE LANGUAGE plpython3u;

CREATE FUNCTION get_json_template() RETURNS JSONB AS $$
BEGIN
   RETURN '{ "is_dirty": false }'::JSONB;
END
$$ LANGUAGE plpgsql;
