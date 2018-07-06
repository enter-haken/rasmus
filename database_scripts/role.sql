SET search_path TO core,public;

-- todo: who can add/update/delete a role
-- todo: seed base roles: admin, readonly
-- json view -> role description with associated privileges
CREATE TABLE role(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(254) UNIQUE NOT NULL,
    description VARCHAR(254),
    role_level role_level NOT NULL DEFAULT 'user',
    json_view JSONB
);

CREATE TABLE role_privilege(
    id_role UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    id_privilege UUID NOT NULL REFERENCES privilege(id) ON DELETE CASCADE,
    can_read BOOLEAN NOT NULL DEFAULT true, 
    can_write BOOLEAN NOT NULL DEFAULT false,
    PRIMARY KEY (id_role, id_privilege)
);

--
-- manager functions
--

CREATE FUNCTION role_manager(request JSONB) RETURNS JSONB AS $$
DECLARE 
    role_response JSONB;
    manager_result JSONB;
BEGIN
    CASE request->>'action'
        WHEN 'get' THEN SELECT core.role_get_manager(request) INTO manager_result;
        WHEN 'add' THEN SELECT core.role_add_manager(request) INTO manager_result;
        WHEN 'delete' THEN SELECT core.role_delete_manager(request) INTO manager_result;
        WHEN 'update' THEN SELECT core.role_update_manager(request) INTO manager_result; 
        ELSE RAISE EXCEPTION 'unknown action `%`. aborting privilege manger', request->>'action';
    END CASE;

    role_response :=  core.get_entity(request->>'entity')
        || jsonb_build_object('data', manager_result);

    RETURN role_response; 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION role_get_manager(request JSONB) RETURNS JSONB AS $$
DECLARE
    response JSONB;
    sql TEXT;
    dirty_ids JSONB;
    dirty_id JSONB;
BEGIN
    -- select only json view
    SELECT core.get_select_statement(request,true) INTO sql;

    sql := 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (' || sql || ') t';
    
    EXECUTE sql INTO response;

    SELECT core.get_ids_for_empty_or_dirty_views(response) INTO dirty_ids;
    
    IF FOUND THEN
        RAISE NOTICE 'dirty or empty ids for %: %', request->>'entity',dirty_ids;

        FOR dirty_id in SELECT * FROM jsonb_array_elements(dirty_ids)
        LOOP
            PERFORM core.get_role_view((dirty_id->>'id')::UUID);
        END LOOP;
        
        EXECUTE sql INTO response;
    END IF;
    
    SELECT core.flatten_json_view_response(response) INTO response;

    RETURN response;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION role_add_manager(request JSONB) RETURNS JSONB AS $$
DECLARE 
    response JSONB;
    role_id UUID;
    sql TEXT;
BEGIN
    SELECT core.get_insert_statement(request) INTO sql;

    EXECUTE sql INTO role_id;

    SELECT row_to_json(p) FROM (SELECT 
        id, 
        name, 
        description, 
        role_level
        FROM core.role 
        WHERE id = role_id) p INTO response;

    RETURN response;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION role_delete_manager(request JSONB) RETURNS JSONB AS $$
DECLARE
    response JSONB;
BEGIN
    IF request->'data' IS NULL THEN
        RAISE EXCEPTION 'data must not be empty when deleting data from role';
    END IF;
    
    IF request#>'{data,id}' IS NULL THEN
        RAISE EXCEPTION 'the id field of the data node must not be empty';
    END IF;

    DELETE FROM core.role WHERE id = (request#>>'{data,id}')::UUID;

    --todo: add a success object to result
    RETURN request; 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION role_update_manager(request JSONB) RETURNS JSONB AS $$
DECLARE
    response JSONB;
    sql TEXT;
BEGIN
    SELECT core.get_update_statement(request) INTO sql;

    EXECUTE sql;
    
    PERFORM core.update_privileges_for_role_if_necessary(request);

    RETURN core.get_role_view((request#>>'{data,id}')::JSONB, true);
    
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_privileges_for_role_if_necessary(raw_request JSONB) RETURNS JSONB AS $$
    import json

    request = json.loads(raw_request)

    if not "data" in request or not "privileges" in request['data']:
        return json.dumps([])

    # -- get current privileges
    # -- diff current privileges with requested ones
    # -- delete privilege relations for current privileges, which are not in requested
    # -- add privilege relations for requested privileges, which ar not in current privileges
    # -- update known privileges if necessary

    # -- TODO: use crud functions


    current_role_privileges = plpy.execute(plpy.prepare("SELECT id_role, id_privilege, can_read, can_write FROM role_privilege WHERE id = $  "))
    
    return json.dumps([])

$$ LANGUAGE plpython3u;

--
-- set roles dirty, when privileges are changed or deleted
-- 

CREATE FUNCTION set_roles_dirty_for_privilege(privilege_id UUID) RETURNS VOID AS $$
DECLARE
    current_role_id UUID;
BEGIN
    FOR current_role_id IN SELECT id_role FROM core.role_privilege WHERE id_privilege = privilege_id
    LOOP
        PERFORM core.set_role_dirty(current_role_id);
        RAISE NOTICE 'role % is set to dirty, because privilege % has been changed or deleted.', current_role_id, privilege_id;
    END LOOP;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION privilege_has_changed_trigger() RETURNS TRIGGER AS $$
BEGIN
    PERFORM core.set_roles_dirty_for_privilege(NEW.id);
    RAISE NOTICE 'privilege % has changed', NEW.id;

    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION privilege_has_been_deleted_trigger() RETURNS TRIGGER AS $$
BEGIN
    PERFORM core.set_roles_dirty_for_privilege(OLD.id);
    RAISE NOTICE 'privilege % has been deleted', OLD.id;

    RETURN OLD;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER privilege_update_trigger BEFORE UPDATE ON privilege
    FOR EACH ROW EXECUTE PROCEDURE privilege_has_changed_trigger();

CREATE TRIGGER privilege_delete_trigger BEFORE DELETE ON privilege
    FOR EACH ROW EXECUTE PROCEDURE privilege_has_been_deleted_trigger();

--
-- role json_view functions
--

CREATE FUNCTION get_role_view(role_id UUID, dirty_read BOOLEAN DEFAULT false) RETURNS JSONB AS $$
DECLARE
    role_raw JSONB;
    role_privileges JSONB;
BEGIN
    IF dirty_read OR EXISTS (SELECT 1 FROM core.role WHERE 
            json_view IS NOT NULL AND 
            (json_view->>'is_dirty')::BOOLEAN = false AND 
            id = role_id) THEN
        SELECT json_view FROM core.role WHERE id = role_id INTO role_raw;
        RAISE NOTICE 'returning undirty role %', role_id;
        RETURN role_raw;
    END IF;

    SELECT row_to_json(role) FROM
        (SELECT id, name, description, role_level FROM core.role WHERE id = role_id) role INTO role_raw;

    SELECT array_to_json(array_agg(privileges)) FROM
        (SELECT p.id, 
            p.name, 
            p.description, 
            p.minimum_read_role_level, 
            p.minimum_write_role_level FROM core.privilege p 
        JOIN core.role_privilege rp on p.id = rp.id_privilege
        JOIN core.role r on r.id = rp.id_role
        WHERE r.id = role_id) privileges INTO role_privileges;

    role_raw := role_raw
        || jsonb_build_object('privileges', role_privileges)
        || core.get_entity('role');

    UPDATE core.role set json_view = role_raw WHERE id = role_id;
    RAISE NOTICE 'update json_view for role %', role_id;

    RETURN role_raw;
END
$$ LANGUAGE plpgsql;
