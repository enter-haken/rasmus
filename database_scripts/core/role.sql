SET search_path TO core,public;

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

CREATE TABLE role_privilege(
    id_role UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
    id_privilege UUID NOT NULL REFERENCES privilege(id) ON DELETE CASCADE,
    can_read BOOLEAN NOT NULL DEFAULT true, 
    can_write BOOLEAN NOT NULL DEFAULT false,
    PRIMARY KEY (id_role, id_privilege)
);

