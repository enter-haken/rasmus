SET search_path TO rasmus,public;

-- these are some  test inserts to transfer
INSERT INTO transfer (request) VALUES ('{"action" : "add", "entity":"privilege", "data": {"name":"dashboard", "description": "show dashboard", "minimum_read_role_level":"user"}}'::JSONB),
    ('{"action" : "add", "entity":"privilege", "data": {"name":"news", "description": "show news feed", "minimum_read_role_level":"user"}}'::JSONB),
    ('{"action" : "add", "entity":"role", "data": {"name":"admin", "description": "the admin can do everything within the instance"}}'::JSONB),
    ('{"action" : "add", "entity":"role", "data": {"name":"user", "description": "this is the standard user role"}}'::JSONB),
    ('{"action" : "add", "entity":"role", "data": {"name":"guest", "description": "this role is used, when a user is not logged in"}}'::JSONB),
    ('{"action" : "add", "entity":"user", "data" : {"first_name":"Jan Frederik", "last_name": "Hake", "email_address": "jan_hake@gmx.de", "login": "jan_hake"}}'::JSONB);

INSERT INTO privilege (name, description) VALUES ('user_management', 'work with systemwide user management'),
    ('role_management', 'work with systemwide role management'),
    ('privilege_management', 'work with systemwide privilege management');

INSERT INTO role (name, description, role_level) VALUES 
    ('admin', 'the admin can do everything within the instance','admin');

-- add all privileges to admin role with read and write permissions
-- this is a test insert
-- it will be removed in future
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

INSERT INTO transfer (request) VALUES ('{"action" : "add", "entity":"privilege", "data": {"name":"dashboard", "description": "show dashboard", "minimum_read_role_level":"user"}}'::JSONB);
INSERT INTO transfer (request) VALUES ('{"action":"get" , "entity":"privilege"}'::JSONB);
INSERT INTO transfer (request) VALUES ('{"action":"get" , "entity":"privilege", "data": { "name" : "dash"}}'::JSONB);

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

INSERT INTO transfer (request) 
        VALUES ('{"action" : "get", "entity":"role"}'::JSONB);

DO $$
DECLARE
    role_id UUID;
BEGIN
    SELECT id FROM rasmus.role WHERE name = 'guest' INTO role_id;
    INSERT INTO transfer (request)
        VALUES (format('{"action":"delete", "entity":"role", "data":{"id":"%1$s"}}', role_id)::JSONB);
END
$$ LANGUAGE plpgsql;
