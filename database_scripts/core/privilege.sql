SET search_path TO core,public;

-- todo: seed application privileges on install
CREATE TABLE privilege(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(80) UNIQUE NOT NULL,
    description VARCHAR(254),
    schema varchar(254) NOT NULL DEFAULT 'core',
    minimum_read_role_level role_level NOT NULL DEFAULT 'admin',
    minimum_write_role_level role_level NOT NULL DEFAULT 'admin'
);

-- todo: detect generic operations
CREATE FUNCTION privilege_manager(request JSONB) RETURNS JSONB AS $$
DECLARE privilege_response JSONB;
DECLARE manager_result JSONB;
BEGIN
    CASE request->>'action'
        WHEN 'get' THEN SELECT core.privilege_get_manager(request) INTO manager_result;
        WHEN 'add' THEN RAISE EXCEPTION '% manager missing for %', request->>'action', request->>'entity';
        WHEN 'delete' THEN RAISE EXCEPTION '% manager missing for %', request->>'action', request->>'entity';
        WHEN 'update' THEN RAISE EXCEPTION '% manager missing for %', request->>'action', request->>'entity';
        ELSE RAISE EXCEPTION 'unknown action `%`. aborting privilege manger', request->>'action';
    END CASE;

    privilege_response := json_build_object('data', manager_result);

    RETURN privilege_response; 
END
$$ LANGUAGE plpgsql;

-- todo: how to react on the payload in data
CREATE FUNCTION privilege_get_manager(request JSONB) RETURNS JSONB AS $$
DECLARE
    response JSONB;
BEGIN
    IF request->'data' IS NULL THEN
        SELECT array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT id, 
                name, 
                description, 
                schema, 
                minimum_read_role_level, 
                minimum_write_role_level 
            FROM core.privilege) t
        INTO response;
        END IF;
    RETURN response;
END
$$ LANGUAGE plpgsql;
