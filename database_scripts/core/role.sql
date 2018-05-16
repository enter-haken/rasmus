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
-- privilege trigger for role changes / deletions
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

CREATE FUNCTION get_role_view(role_id UUID) RETURNS JSONB AS $$
DECLARE
    role_raw JSONB;
    role_privileges JSONB;
BEGIN
    IF EXISTS (SELECT 1 FROM core.role WHERE (json_view->>'is_dirty')::BOOLEAN = false) THEN
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
        || get_entity('role');

    UPDATE core.role set json_view = role_raw WHERE id = role_id;
    RAISE NOTICE 'update json_view for role %', role_id;

    RETURN role_raw;
END
$$ LANGUAGE plpgsql;

