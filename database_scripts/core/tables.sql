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


