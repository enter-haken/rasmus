SET search_path TO rasmus,public;

-- todo: json_view

-- {
--   "id_user" : "xxx",
--   "first_name" : "Jan",
--   "last_name" : "Hake",
--   "url" : "https://enter-haken.github.io",
--   "notes" : "cool guy",
--   "phones" : [{
--     "number" : "0123456",
--     "is_primary" : true
--   }],
--   "emails": [{ 
--     "email" : "jan_hake@gmx.de",
--     "is_primary" : true
--   }],
--   "addresses" : [{
--     "street" : "Fakestreet",
--     "housenumber" : "123",
--     "zip" : "12345",
--     "city" : "Springfield"
--   }]
-- }

CREATE TABLE person(
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  id_owner UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  first_name VARCHAR(512), 
  last_name VARCHAR(512),
  url VARCHAR(2048),
  notes VARCHAR(4096),
  birthday DATE,
  json_view JSONB
);

CREATE TABLE phone(
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  "number" VARCHAR(128) NOT NULL
);

CREATE TYPE phone_kind AS ENUM ('mobile','landline');
CREATE TYPE private_or_work AS ENUM ('private', 'work');

CREATE TABLE person_phone(
  id_person UUID NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  id_phone UUID NOT NULL REFERENCES phone(id) ON DELETE CASCADE,
  phone_kind phone_kind NOT NULL DEFAULT 'landline',
  private_or_work private_or_work NOT NULL DEFAULT 'private',
  is_primary BOOLEAN NOT NULL DEFAULT false,
  PRIMARY KEY (id_person, id_phone)
);

CREATE TABLE email(
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(254) NOT NULL  
);

CREATE TABLE person_email(
  id_person UUID NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  id_email UUID NOT NULL REFERENCES email(id) ON DELETE CASCADE,
  private_or_work private_or_work NOT NULL DEFAULT 'private',
  is_primary BOOLEAN NOT NULL DEFAULT false,
  PRIMARY KEY (id_person, id_email) 
);

-- todo: normalize if necessary
CREATE TABLE address(
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  street VARCHAR(512),
  housenumber VARCHAR(16),
  zip VARCHAR(16),
  city VARCHAR(128),
  po_box VARCHAR(128)
);

CREATE TABLE person_address(
  id_person UUID NOT NULL REFERENCES person(id) ON DELETE CASCADE,
  id_address UUID NOT NULL REFERENCES address(id) ON DELETE CASCADE,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  private_or_work private_or_work NOT NULL DEFAULT 'private',
  PRIMARY KEY (id_person, id_address)
);

--todo:
-- add chat
-- add social media / private and work
