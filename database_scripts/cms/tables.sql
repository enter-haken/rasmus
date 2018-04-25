SET search_path TO cms,public;

-- todo: save cms global settings like templates

CREATE TABLE article(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    id_author UUID NOT NULL REFERENCES core.user_account(id),
    title VARCHAR(254),
    raw text,
    html text,
    is_visible boolean NOT NULL DEFAULT FALSE,
    is_draft boolean NOT NULL DEFAULT TRUE
);

-- todo: define types, needed by the cms
CREATE TYPE file_type AS ENUM (
    'binary',
    'jpeg',
    'png',
    'mp3',
    'mp4',
    'mkv'
);

CREATE TABLE attachment(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    raw bytea NOT NULL,
    file_type file_type NOT NULL DEFAULT 'binary'
);

CREATE TABLE article_attachment(
    id_article UUID NOT NULL REFERENCES article(id),
    id_attachment UUID NOT NULL REFERENCES attachment(id),
    PRIMARY KEY(id_article, id_attachment)
);

CREATE TABLE category(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(254) NOT NULL,
    description VARCHAR(512),
    icon VARCHAR(1), -- font awesome
    is_active BOOLEAN NOT NULL DEFAULT false,
    is_visible BOOLEAN NOT NULL DEFAULT false,
    LNUM INTEGER NOT NULL,
    RNUM INTEGER NOT NULL
);

CREATE TABLE article_in_category(
    id_article UUID NOT NULL REFERENCES article(id),
    id_category UUID NOT NULL REFERENCES category(id),
    PRIMARY KEY(id_article, id_category)
);

