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
    current_table TEXT;
BEGIN
    FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = 'core'
    LOOP
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
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    current_table TEXT;
   _sql TEXT; 
BEGIN
    FOR current_table IN SELECT table_name FROM information_schema.columns 
        WHERE table_schema = 'core' AND column_name = 'json_view'
    LOOP
        EXECUTE format('CREATE FUNCTION set_%1$s_dirty(%1$s_id UUID) RETURNS VOID AS %2$s%2$s
        BEGIN
            UPDATE %1$s SET json_view = jsonb_set(json_view, ''{is_dirty}'', ''true'') 
                WHERE id = %1$s_id;
        END
        %2$s%2$s LANGUAGE plpgsql;', current_table, '$');
        
        EXECUTE format('CREATE FUNCTION set_%1$s_undirty(%1$s_id UUID) RETURNS VOID AS %2$s%2$s
        BEGIN
            UPDATE %1$s SET json_view = jsonb_set(json_view, ''{is_dirty}'', ''false'') 
                WHERE id = %1$s_id;
        END
        %2$s%2$s LANGUAGE plpgsql;', current_table, '$');

    END LOOP;
END
$$ LANGUAGE plpgsql;
