SET search_path TO core,public;

CREATE TABLE appointment(
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  id_user UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  id_address UUID NOT NULL REFERENCES address(id) ON DELETE CASCADE, 
  -- todo: past events
  -- should the appointment be deleted, if the address does not exists any more? 
  -- one empty address entity?
  "from" TIMESTAMP NOT NULL DEFAULT now(),
  "to" TIMESTAMP NOT NULL DEFAULT now(),
  is_whole_day BOOLEAN NOT NULL DEFAULT false,
  description VARCHAR(512),
  json_view JSONB
);

CREATE TABLE person_appointment(
  id_appointment UUID NOT NULL REFERENCES appointment(id) ON DELETE CASCADE,
  id_person UUID NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  private_or_work private_or_work NOT NULL DEFAULT 'private',
  PRIMARY KEY (id_person, id_appointment)
);

