SET search_path TO core,public;

--
-- privilege 
--

CREATE FUNCTION core.set_roles_dirty_for_privilege(privilege_id UUID) RETURNS VOID AS $$
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
-- role 
--

CREATE FUNCTION set_user_account_dirty_for_role(role_id UUID) RETURNS VOID AS $$
DECLARE
    current_user_account_id UUID;
BEGIN
    FOR current_user_account_id IN SELECT id_user_account FROM user_in_role WHERE id_role = role_id
    LOOP
        PERFORM set_user_account_dirty(current_user_account_id);
        RAISE NOTICE 'user account % is set to dirty, because role % has changed', current_user_account_id, role_id;
    END LOOP;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION role_changed_trigger() RETURNS TRIGGER AS $$
BEGIN
    PERFORM set_user_account_dirty_for_role(NEW.id);
    
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
    FOR EACH ROW EXECUTE PROCEDURE role_changed_trigger();

CREATE TRIGGER role_delete_trigger AFTER DELETE ON role
    FOR EACH ROW EXECUTE PROCEDURE role_changed_trigger();

--
-- user_account trigger
--

CREATE FUNCTION user_account_changed() RETURNS TRIGGER AS $$
BEGIN
    -- todo: generic check for other entity values changes
    IF OLD.json_view IS NULL OR NEW.json_view <> OLD.json_view THEN
        RAISE NOTICE 'Only the json_view for role % has changed. The role it self does not change.', NEW.id;
        RETURN NEW;
    END IF;

    NEW.json_view = jsonb_set(NEW.json_view, '{is_dirty}', 'true');
    RETURN NEW;

END
$$ LANGUAGE plpgsql;

CREATE FUNCTION user_account_created() RETURNS TRIGGER AS $$
DECLARE
    password TEXT; 
BEGIN
    SELECT gen_salt('bf') INTO password;
    RAISE NOTICE 'blank password: %', password;
    RAISE NOTICE 'salt: %', NEW.salt;
    SELECT crypt(password, NEW.salt) INTO password;
    NEW.password = password;
    RAISE NOTICE 'crypted password: %', NEW.password;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_account_created_trigger BEFORE INSERT ON user_account
    FOR EACH ROW EXECUTE PROCEDURE user_account_created();

CREATE TRIGGER user_account_changed_trigger BEFORE UPDATE ON user_account
    FOR EACH ROW EXECUTE PROCEDURE user_account_changed();

--
-- update json views
--

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
        || get_entity('role');

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
        || get_entity('user_account');
    
    UPDATE user_account SET json_view = user_raw WHERE id = user_id;
    RAISE NOTICE 'the json_view for user_account % has been updated', user_id;
    
    RETURN user_raw;
END
$$ LANGUAGE plpgsql;

-- currently used for reset user_account views
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
