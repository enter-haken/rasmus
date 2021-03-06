SET search_path TO rasmus,public;

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
    FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = 'rasmus'
    LOOP
        RAISE NOTICE 'added created_at column to %', row.tablename;
        EXECUTE 'ALTER TABLE "' || row.tablename ||
            '" ADD COLUMN created_at timestamp NOT NULL DEFAULT NOW();';

        RAISE NOTICE 'added updated_at column to %', row.tablename;
        EXECUTE 'ALTER TABLE "' || row.tablename ||
            '" ADD COLUMN updated_at timestamp NOT NULL DEFAULT NOW();';
        
        RAISE NOTICE 'added deleted_at column to %', row.tablename;
        EXECUTE 'ALTER TABLE "' || row.tablename ||
            '" ADD COLUMN deleted boolean NOT NULL DEFAULT false';

        RAISE NOTICE 'create %_metadata_trigger', row.tablename;
        EXECUTE 'CREATE TRIGGER ' || row.tablename || '_metadata_trigger BEFORE UPDATE ON "' || row.tablename ||
            '" FOR EACH ROW EXECUTE PROCEDURE metadata_trigger();';
    END LOOP;
END
$$ LANGUAGE plpgsql;

-- if a table with a `json_column` is set to dirty
-- a message is send to the backend
CREATE FUNCTION send_message_on_set_dirty_trigger() RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.json_view->>'is_dirty')::BOOLEAN THEN
        PERFORM rasmus.send_dirty_message(NEW.id, NEW.json_view->>'entity');
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- add set_xxx_dirty and set_xxx_undirty functions to every table, having a `json_view` column
DO $$
DECLARE
    current_table TEXT;
   _sql TEXT; 
BEGIN
    FOR current_table IN SELECT table_name FROM information_schema.columns 
        WHERE table_schema = 'rasmus' AND column_name = 'json_view'
    LOOP
        RAISE NOTICE 'create set_%_dirty(%_id  UUID)', current_table, current_table;
        EXECUTE format('CREATE FUNCTION rasmus.set_%1$s_dirty(%1$s_id UUID) RETURNS VOID AS %2$s%2$s
        BEGIN
            UPDATE rasmus."%1$s" SET json_view = jsonb_set(json_view, ''{is_dirty}'', ''true'') 
                WHERE id = %1$s_id;
        END
        %2$s%2$s LANGUAGE plpgsql;', current_table, '$');
        
        RAISE NOTICE 'create set_%_undirty(%_id  UUID)', current_table, current_table;
        EXECUTE format('CREATE FUNCTION rasmus.set_%1$s_undirty(%1$s_id UUID) RETURNS VOID AS %2$s%2$s
        BEGIN
            UPDATE rasmus."%1$s" SET json_view = jsonb_set(json_view, ''{is_dirty}'', ''false'') 
                WHERE id = %1$s_id;
        END
        %2$s%2$s LANGUAGE plpgsql;', current_table, '$');
        
        RAISE NOTICE 'create rasmus.%_send_message_on_set_dirty_trigger', current_table;
        EXECUTE 'CREATE TRIGGER ' || current_table || '_send_message_on_set_dirty_trigger AFTER UPDATE ON "' || current_table ||
            '" FOR EACH ROW EXECUTE PROCEDURE rasmus.send_message_on_set_dirty_trigger();';

    END LOOP;
END
$$ LANGUAGE plpgsql;
