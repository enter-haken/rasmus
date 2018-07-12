SET search_path TO rasmus,public;

--
--
--
-- DO NOT USE IN PRODUCTION
--
--
--
--

--
-- these tasks should be done by the entity managers
-- 

DO $$
DECLARE
    admin_role_id UUID;
    admin_user_id UUID;
    priv record;
BEGIN
    SELECT id from role INTO admin_role_id;
    FOR priv in SELECT id FROM privilege
    LOOP
        INSERT INTO role_privilege(id_role,id_privilege, can_write) VALUES
            (admin_role_id, priv.id, true);
    END LOOP;

    --PERFORM get_role_view(admin_role_id);

    --todo: this should be done during installation
    --todo: workflow: insert into transfer with email address
    --todo: workflow: add admin role to newly created admin user
    --todo: workflow: send email with password to new site admin
    INSERT INTO "user" (login, email_address, maximum_role_level) VALUES
        ('admin','admin@admin.com', 'admin') RETURNING id into admin_user_id;

    INSERT INTO user_in_role (id_user, id_role) VALUES
        (admin_user_id, admin_role_id);

    PERFORM rasmus.get_user_view(admin_user_id);

    DELETE from privilege where name = 'dashboard';

END
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    privilege_id UUID;
BEGIN
    -- the transfer insert is async
    PERFORM pg_sleep(3);
    SELECT id INTO privilege_id FROM rasmus.privilege WHERE "name" = 'dashboard';

    -- some update test
    INSERT INTO transfer (request) 
        VALUES (format('{"action" : "update", "entity":"privilege", "data": {"id" : "%1$s", "name":"dashboard2"}}', privilege_id)::JSONB);

    INSERT INTO transfer (request) 
        VALUES (format('{"action" : "update", "entity":"privilege", "data": {"id" : "%1$s", "name":"dashboard3", "description" : "updated desc"}}', privilege_id)::JSONB);

    SELECT id INTO privilege_id FROM rasmus.privilege WHERE "name" = 'user_management';
    RAISE NOTICE '%',privilege_id;
    
    INSERT INTO transfer (request) 
        VALUES (format('{"action" : "update", "entity":"privilege", "data": {"id" : "%1$s", "description" : "user management_desc"}}', privilege_id)::JSONB);
END
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    role_id UUID;
BEGIN
    SELECT id FROM rasmus.role WHERE name = 'guest' INTO role_id;
    INSERT INTO transfer (request)
        VALUES (format('{"action":"delete", "entity":"role", "data":{"id":"%1$s"}}', role_id)::JSONB);
END
$$ LANGUAGE plpgsql;
