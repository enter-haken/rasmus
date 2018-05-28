SET search_path TO core,public;

--todo: seed admin account? during install?
--json view -> user + roles + privileges
CREATE TABLE user_account(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(254),
    last_name VARCHAR(254),
    email_address VARCHAR(254) NOT NULL,
    password VARCHAR(254),
    salt VARCHAR(30) NOT NULL DEFAULT gen_salt('bf'),
    login VARCHAR(254) UNIQUE NOT NULL,
    signature VARCHAR(254),
    maximum_role_level role_level NOT NULL DEFAULT 'user',
    json_view JSONB
);

CREATE TABLE user_in_role(
    id_user_account UUID NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    id_role UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    PRIMARY KEY(id_user_account, id_role)
);

--
-- role trigger, which can set a user_account to dirty
--

CREATE FUNCTION set_user_account_dirty_for_role(role_id UUID) RETURNS VOID AS $$
DECLARE
    current_user_account_id UUID;
BEGIN
    FOR current_user_account_id IN SELECT id_user_account FROM core.user_in_role WHERE id_role = role_id
    LOOP
        PERFORM core.set_user_account_dirty(current_user_account_id);
        RAISE NOTICE 'user account % is set to dirty, because role % has changed', current_user_account_id, role_id;
    END LOOP;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION role_changed_trigger() RETURNS TRIGGER AS $$
BEGIN
    PERFORM core.set_user_account_dirty_for_role(NEW.id);
    
    -- todo: generic check for other entity values changes
    IF OLD.json_view IS NULL OR NEW.json_view <> OLD.json_view THEN
        RAISE NOTICE 'user_account: Only the json_view for role % has changed. The role it self does not change.', NEW.id;
        RETURN NEW;
    END IF;

    NEW.json_view = jsonb_set(NEW.json_view, '{is_dirty}', 'true');
    RAISE NOTICE 'user_account: role % is set to to dirty', NEW.id;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER role_update_trigger BEFORE UPDATE ON role
    FOR EACH ROW EXECUTE PROCEDURE role_changed_trigger();

CREATE TRIGGER role_delete_trigger AFTER DELETE ON role
    FOR EACH ROW EXECUTE PROCEDURE role_changed_trigger();

--
-- user_account related change / deletion triggers
--

CREATE FUNCTION user_account_changed() RETURNS TRIGGER AS $$
BEGIN
    -- todo: generic check for other entity values changes
    IF OLD.json_view IS NULL OR NEW.json_view <> OLD.json_view THEN
        RAISE NOTICE 'user_account: Only the json_view for role % has changed. The role it self does not change.', NEW.id;
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
-- user_account json_view functions
--

CREATE FUNCTION get_user_view(user_id UUID) RETURNS JSONB AS $$
DECLARE
    user_raw JSONB;
    user_roles JSONB;
    role_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM core.user_account WHERE (json_view->>'is_dirty')::BOOLEAN = false) THEN
        SELECT json_view FROM core.user_account WHERE id = user_id INTO user_raw;
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

    FOR role_id IN SELECT id_role FROM core.user_in_role uir WHERE uir.id_user_account = user_id
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
    FOR user_id IN SELECT id FROM core.user_account WHERE (json_view->>'is_dirty')::boolean = true
    LOOP
        PERFORM core.get_user_view(user_id);
    END LOOP;
END
$$ LANGUAGE plpgsql;
