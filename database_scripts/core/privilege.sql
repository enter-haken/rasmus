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
DECLARE 
    privilege_response JSONB;
    manager_result JSONB;
BEGIN
    CASE request->>'action'
        WHEN 'get' THEN SELECT core.privilege_get_manager(request) INTO manager_result;
        WHEN 'add' THEN SELECT core.privilege_add_manager(request) INTO manager_result;
        WHEN 'delete' THEN SELECT core.privilege_delete_manager(request) INTO manager_result;
        WHEN 'update' THEN SELECT core.privilege_update_manager(request) INTO manager_result; 
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
    sql TEXT;
BEGIN
    SELECT core.get_insert_statement(request) INTO sql;

    EXECUTE sql INTO privilege_id;

    SELECT row_to_json(p) FROM (SELECT 
        id, 
        name, 
        description, 
        schema, 
        minimum_read_role_level, 
        minimum_write_role_level 
        FROM core.privilege 
        WHERE id = privilege_id) p INTO response;

    RETURN response;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION privilege_update_manager(request JSONB) RETURNS JSONB AS $$
DECLARE 
    response JSONB;
    sql TEXT;
BEGIN

    SELECT core.get_update_statement(request) INTO sql;

    EXECUTE sql;

    SELECT row_to_json(p) FROM (SELECT 
        id, 
        name, 
        description, 
        schema, 
        minimum_read_role_level, 
        minimum_write_role_level
        FROM core.privilege 
        WHERE id = (request#>>'{data,id}')::UUID) p INTO response;

    RETURN response;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION privilege_get_manager(request JSONB) RETURNS JSONB AS $$
DECLARE
    response JSONB;
    sql TEXT;
BEGIN
    SELECT core.get_select_statement(request) INTO sql;

    sql := 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (' || sql || ') t';
    
    EXECUTE sql INTO response;

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
