SET search_path TO core,public;

-- this script should be executed after all DDL stuff is done.

CREATE FUNCTION metadata_trigger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.deleted = true THEN
        RAISE EXCEPTION 'can not update the deleted record %', NEW.id::text;
    END IF;

    NEW.updated_at := now();
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- add created_at and updated_at columns to every table
-- and add update trigger to every table

DO $$
DECLARE
    row record;
BEGIN
    FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = 'core' LOOP
        EXECUTE 'ALTER TABLE ' || row.tablename ||
            ' ADD COLUMN created_at timestamp NOT NULL DEFAULT NOW();';

        EXECUTE 'ALTER TABLE ' || row.tablename ||
            ' ADD COLUMN updated_at timestamp NOT NULL DEFAULT NOW();';

        EXECUTE 'ALTER TABLE ' || row.tablename ||
            ' ADD COLUMN deleted boolean NOT NULL DEFAULT false';

        EXECUTE 'CREATE TRIGGER ' || row.tablename || '_trigger BEFORE UPDATE ON ' || row.tablename ||
            ' FOR EACH ROW EXECUTE PROCEDURE metadata_trigger();';
    END LOOP;
END
$$ LANGUAGE plpgsql
