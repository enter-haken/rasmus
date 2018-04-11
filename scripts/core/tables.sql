SET search_path TO core,public;

--todo: seed admin account? during install?
--json view -> user + roles + privileges
CREATE TABLE user_account(
	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(254),
    last_name VARCHAR(254),
    email_address VARCHAR(254) NOT NULL,
    password VARCHAR(254), --> todo: not null -> generate and send mail with credentials
    login VARCHAR(254) UNIQUE NOT NULL,
    signature VARCHAR(254),
    json_view JSONB
);

CREATE TYPE role_level AS ENUM ('admin','user','default');

-- todo: who can add/update/delete a role
-- todo: seed base roles: admin, readonly
-- json view -> role description with associated privileges
CREATE TABLE role(
	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(254) UNIQUE NOT NULL,
    description VARCHAR(254),
    role_level role_level NOT NULL DEFAULT 'default',
    json_view JSONB
);

CREATE TABLE user_in_role(
    id_user_account UUID NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    id_role UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    PRIMARY KEY(id_user_account, id_role)
);

-- todo: seed application privileges on install
CREATE TABLE privilege(
	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(80) UNIQUE,
    description VARCHAR(254),
    schema varchar(254) NOT NULL DEFAULT 'core',
    minimum_read_role_level role_level NOT NULL DEFAULT 'admin',
    minimum_write_role_level role_level NOT NULL DEFAULT 'admin'
);

CREATE TABLE role_privilege(
    id_role UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    id_privilege UUID NOT NULL REFERENCES privilege(id) ON DELETE CASCADE,
    can_read BOOLEAN NOT NULL DEFAULT true, 
    can_write BOOLEAN NOT NULL DEFAULT false,
    PRIMARY KEY (id_role, id_privilege)
);

CREATE FUNCTION set_roles_dirty_for_privilege_change(privilege_id UUID) RETURNS VOID AS $$
DECLARE
    current_role_id UUID;
BEGIN
    FOR current_role_id IN SELECT id_role FROM role_privilege WHERE id_privilege = privilege_id
    LOOP
        PERFORM set_role_dirty(current_role_id);
        RAISE NOTICE 'role % is set to dirty, because privilege % has been changed or deleted.', current_role_id, privilege_id;
    END LOOP;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION set_user_account_dirty_for_role_change(role_id UUID) RETURNS VOID AS $$
DECLARE
    current_id UUID;
BEGIN
    FOR current_id IN SELECT id_user_account FROM user_in_role WHERE id_role = role_id
    LOOP
        PERFORM set_user_account_dirty(current_id);
        RAISE NOTICE 'user account % is set to dirty, because role % has changed', current_id, role_id;
    END LOOP;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION privilege_has_changed() RETURNS TRIGGER AS $$
BEGIN
    PERFORM set_roles_dirty_for_privilege_change(NEW.id);
    RAISE NOTICE 'privilege % has changed', NEW.id;

    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION privilege_has_been_deleted() RETURNS TRIGGER AS $$
BEGIN
    PERFORM set_roles_dirty_for_privilege_change(OLD.id);
    RAISE NOTICE 'privilege % has been deleted', OLD.id;

    RETURN OLD;
END
$$ LANGUAGE plpgsql;


CREATE TRIGGER privilege_update_trigger BEFORE UPDATE ON privilege
    FOR EACH ROW EXECUTE PROCEDURE privilege_has_changed();

CREATE TRIGGER privilege_delete_trigger BEFORE DELETE ON privilege
    FOR EACH ROW EXECUTE PROCEDURE privilege_has_been_deleted();

CREATE FUNCTION role_changed() RETURNS TRIGGER AS $$
BEGIN
    PERFORM set_user_account_dirty_for_role_change(NEW.id);
    
    -- todo: generic check for other entity values changes
    IF OLD.json_view IS NULL OR NEW.json_view <> OLD.json_view THEN
        RAISE NOTICE 'Only the json_view for role % has changed. The role it self does not change.', NEW.id;
        RETURN NEW;
    END IF;

    NEW.json_view = jsonb_set(NEW.json_view, '{is_dirty}', 'true');
    RAISE NOTICE 'role % is set to to dirty', NEW.id;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER role_update_trigger BEFORE UPDATE ON role
    FOR EACH ROW EXECUTE PROCEDURE role_changed();

CREATE TRIGGER role_delete_trigger AFTER DELETE ON role
    FOR EACH ROW EXECUTE PROCEDURE role_changed();

-- When inserting a new role, there are no asociated privileges
-- there are no users associated with this new role
-- -> no need for a trigger
---CREATE TRIGGER role_insert_trigger AFTER INSERT ON role
--    FOR EACH ROW EXECUTE PROCEDURE role_changed();


CREATE FUNCTION get_role_view(role_id UUID) RETURNS JSONB AS $$
DECLARE
    role_raw JSONB;
    role_privileges JSONB;
BEGIN
    IF EXISTS (SELECT 1 FROM role WHERE (json_view->>'is_dirty')::BOOLEAN = false) THEN
        SELECT json_view FROM role WHERE id = role_id INTO role_raw;
        RAISE NOTICE 'returning undirty role %', role_id;
        RETURN role_raw;
    END IF;

    SELECT row_to_json(role) FROM
        (SELECT id, name, description, role_level FROM role WHERE id = role_id) role INTO role_raw;

    SELECT array_to_json(array_agg(privileges)) FROM
        (SELECT p.id, 
            p.name, 
            p.description, 
            p.minimum_read_role_level, 
            p.minimum_write_role_level FROM privilege p 
        JOIN role_privilege rp on p.id = rp.id_privilege
        JOIN role r on r.id = rp.id_role
        WHERE r.id = role_id) privileges INTO role_privileges;

    role_raw := role_raw
        || jsonb_build_object('privileges', role_privileges)
        || get_json_template();

    UPDATE role set json_view = role_raw WHERE id = role_id;
    RAISE NOTICE 'update json_view for role %', role_id;

    RETURN role_raw;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_user_view(user_id UUID) RETURNS JSONB AS $$
DECLARE
    user_raw JSONB;
    user_roles JSONB;
    role_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM user_account WHERE (json_view->>'is_dirty')::BOOLEAN = false) THEN
        SELECT json_view FROM user_account WHERE id = user_id INTO user_raw;
        RAISE NOTICE 'returning undirty user_account %', user_id;
        RETURN user_raw;
    END IF;

    SELECT row_to_json(u) FROM
        (SELECT id, 
            first_name, 
            last_name, 
            email_address, 
            login, 
            signature FROM user_account 
         WHERE id = user_id) u INTO user_raw;

    user_roles := '[]'::JSONB;

    FOR role_id IN SELECT id_role FROM user_in_role uir WHERE uir.id_user_account = user_id
    LOOP
        RAISE NOTICE 'get_role_view during get user json_view';
        user_roles := user_roles || get_role_view(role_id);
    END LOOP;

    --todo: generic update dirty jsonviews
    user_raw := user_raw
        || jsonb_build_object('roles', user_roles)
        || get_json_template();
    
    UPDATE user_account SET json_view = user_raw WHERE id = user_id;
    RAISE NOTICE 'the json_view for user_account % has been updated', user_id;
    
    RETURN user_raw;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_dirty_user_account() RETURNS VOID AS $$
DECLARE 
    user_id UUID;
BEGIN
    FOR user_id IN SELECT id FROM user_account WHERE (json_view->>'is_dirty')::boolean = true
    LOOP
        PERFORM get_user_view(user_id);
    END LOOP;
END
$$ LANGUAGE plpgsql;
