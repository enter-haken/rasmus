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
        WHEN 'add' THEN SELECT core.privilege_add_manager(request) INTO manager_result;
        WHEN 'delete' THEN SELECT core.privilege_delete_manager(request) INTO manager_result;
        WHEN 'update' THEN RAISE EXCEPTION '% manager missing for %', request->>'action', request->>'entity';
        ELSE RAISE EXCEPTION 'unknown action `%`. aborting privilege manger', request->>'action';
    END CASE;

    privilege_response :=  core.get_entity(request->>'entity')
        || jsonb_build_object('data', manager_result);

    RETURN privilege_response; 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION privilege_add_manager(request JSONB) RETURNS JSONB AS $$
DECLARE 
    response JSONB;
    privilege_id UUID;
BEGIN
    IF request->'data' IS NULL THEN
        RAISE EXCEPTION 'data must not be empty when adding new data to privilege';
    END IF;

    RAISE NOTICE '%', request;

    --todo: find a way to make one insert statement
    INSERT INTO core.privilege (name) VALUES (request#>>'{data,name}') RETURNING id INTO privilege_id;

    IF request#>'{data,description}' IS NOT NULL THEN
        UPDATE core.privilege SET description = request#>>'{data,description}' WHERE id = privilege_id;
    END IF;

    IF request#>'{data,schema}' IS NOT NULL THEN
        UPDATE core.privilege SET schema = request#>>'{data,schema}' WHERE id = privilege_id;
    END IF;

    IF request#>'{data,minimum_read_role_level}' IS NOT NULL THEN
        UPDATE core.privilege SET minimum_read_role_level = (request#>>'{data,minimum_read_role_level}')::core.role_level WHERE id = privilege_id;
    END IF;

    IF request#>'{data,minimum_write_role_level}' IS NOT NULL THEN
        UPDATE core.privilege SET minimum_write_role_level = (request#>>'{data,minimum_write_role_level}')::core.role_level WHERE id = privilege_id;
    END IF;
    
    SELECT row_to_json(p) FROM (SELECT id, name, description, schema, minimum_read_role_level, minimum_write_role_level FROM core.privilege WHERE id = privilege_id) p INTO response;

    --RAISE NOTICE '%', response;
    RETURN response;

END
$$ LANGUAGE plpgsql;

CREATE FUNCTION privilege_get_manager(request JSONB) RETURNS JSONB AS $$
DECLARE
    response JSONB;
    data_name TEXT;
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

    IF request#>'{data,id}' IS NOT NULL THEN
        SELECT array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT id, 
                name, 
                description, 
                schema, 
                minimum_read_role_level, 
                minimum_write_role_level 
            FROM core.privilege WHERE id = (request#>>'{data,id}')::UUID) t
        INTO response;
    END IF;

    IF request#>'{data,name}' IS NOT NULL THEN
        data_name := ('%' || request#>>'{data,name}' || '%')
        SELECT array_to_json(array_agg(row_to_json(t)))
        FROM (
            SELECT id, 
                name, 
                description, 
                schema, 
                minimum_read_role_level, 
                minimum_write_role_level 
            FROM core.privilege WHERE name LIKE ('%' || data_name || '%')) t
        INTO response;
    END IF;

    RETURN response;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION privilege_delete_manager(request JSONB) RETURNS JSONB AS $$
DECLARE
    response JSONB;
BEGIN
    IF request->'data' IS NULL THEN
        RAISE EXCEPTION 'data must not be empty when deleting data from privilege';
    END IF;
    
    IF request#>'{data,id}' IS NULL THEN
        RAISE EXCEPTION 'the id field of the data node must not be empty';
    END IF;

    DELETE FROM privilege WHERE id = (request#>>'{data,id}')::UUID;

    --todo: add a success object to result
    RETURN request; 
END
$$ LANGUAGE plpgsql;
