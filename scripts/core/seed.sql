SET search_path TO core,public;

INSERT INTO privilege (name, description) VALUES ('dashboaord', 'show dashboard');

INSERT INTO role (name, description) VALUES 
    ('admin', 'the admin can do everything within the instance'),
    ('user', 'this is the standard user role'),
    ('guest', 'this role is used, when a user is not logged in');

INSERT INTO user_account (first_name, last_name, email_address, login) VALUES
    ('Jan Frederik', 'Hake', 'jan_hake@gmx.de', 'jan_hake'),
    ('Jemand', 'Anders', 'jemand@anders.de', 'jemand_anders');

-- todo: find a more generic way to insert n-m relations
DO $$
DECLARE 
    id_jan UUID;
    id_jemand UUID;
    id_admin UUID;
    id_user UUID;
BEGIN    
    SELECT id INTO id_jan FROM user_account WHERE first_name = 'Jan Frederik'; 
    SELECT id INTO id_admin FROM role WHERE name = 'admin';
    
    INSERT INTO user_in_role (id_user_account, id_role) VALUES
        (id_jan, id_admin);

    SELECT id INTO id_jemand FROM user_account WHERE first_name = 'Jemand'; 
    SELECT id INTO id_user FROM role WHERE name = 'user';
    
    INSERT INTO user_in_role (id_user_account, id_role) VALUES
        (id_jemand, id_user);

    INSERT INTO transfer (request) VALUES 
    ('{ "schema": "core"}'::JSONB);

END
$$ LANGUAGE plpgsql
