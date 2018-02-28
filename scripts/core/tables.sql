SET search_path TO core,public;

CREATE TABLE user_account(
	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(254),
    last_name VARCHAR(254),
    email_address VARCHAR(254),
    password VARCHAR(254),
    login VARCHAR(254),
    signature VARCHAR(254)
);

CREATE TYPE role_level AS ENUM ('admin','user','guest');

CREATE TABLE role(
	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(254) NOT NULL,
    description VARCHAR(254),
    role_level role_level NOT NULL DEFAULT 'guest'
);

CREATE TABLE user_in_role(
    id_user_account UUID NOT NULL REFERENCES user_account(id),
    id_role UUID NOT NULL REFERENCES role(id),
    PRIMARY KEY(id_user_account, id_role)
);

CREATE TABLE privilege(
	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(80),
    description VARCHAR(254)
);

CREATE TABLE role_privilege(
    id_role UUID NOT NULL REFERENCES role(id),
    id_privilege UUID NOT NULL REFERENCES privilege(id),
    PRIMARY KEY (id_role, id_privilege)
);

