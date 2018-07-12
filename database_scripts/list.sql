SET search_path TO rasmus,public;

CREATE TABLE list(
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  id_owner UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  description VARCHAR(512),
  private_or_work private_or_work NOT NULL DEFAULT 'private',
  json_view JSONB
);

-- todo: access
-- who can CRUD a list item
CREATE TABLE list_item(
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  id_list UUID NOT NULL REFERENCES list(id) ON DELETE CASCADE,
  id_added_by UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  title VARCHAR(128) NOT NULL,
  description VARCHAR(512),
  is_checked BOOLEAN NOT NULL DEFAULT false
);

