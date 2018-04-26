SET search_path TO core,public;

CREATE TABLE transfer(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    state transfer_state NOT NULL DEFAULT 'pending',
    request JSONB NOT NULL,
    result JSONB
);

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

CREATE TABLE user_in_role(
    id_user_account UUID NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    id_role UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    PRIMARY KEY(id_user_account, id_role)
);

-- todo: seed application privileges on install
CREATE TABLE privilege(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(80) UNIQUE NOT NULL,
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

