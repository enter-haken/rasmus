SET search_path TO core,public;

-- these are some  test inserts to transfer
INSERT INTO transfer (request) VALUES ('{"action" : "add", "schema":"core", "entity":"privilege", "payload": {"name":"dasboard", "description": "show dashboard", "role_level":"guest"}}'::JSONB),
    ('{"action" : "add", "schema":"core", "entity":"privilege", "payload": {"name":"news", "description": "show news feed", "role_level":"guest"}}'::JSONB),
    ('{"action" : "add", "schema":"core", "entity":"role", "payload": {"name":"admin", "description": "the admin can do everything within the instance"}}'::JSONB),
    ('{"action" : "add", "schema":"core", "entity":"role", "payload": {"name":"user", "description": "this is the standard user role"}}'::JSONB),
    ('{"action" : "add", "schema":"core", "entity":"role", "payload": {"name":"guest", "description": "this role is used, when a user is not logged in"}}'::JSONB),
    ('{"action" : "add", "schema":"core", "entity":"user_account", "payload" : {"first_name":"Jan Frederik", "last_name": "Hake", "email_address": "jan_hake@gmx.de", "login": "jan_hake"}}'::JSONB);

INSERT INTO privilege (name, description, minimum_read_role_level) VALUES ('dashboard', 'manage system dashboard', 'user');
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
    INSERT INTO user_account (login,email_address, maximum_role_level) VALUES
        ('admin','admin@admin.com', 'admin') RETURNING id into admin_user_id;

    INSERT INTO user_in_role (id_user_account, id_role) VALUES
        (admin_user_id, admin_role_id);

    PERFORM get_user_view(admin_user_id);

    DELETE from privilege where name = 'dashboard';

END
$$ LANGUAGE plpgsql

