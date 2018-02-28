SET search_path TO core,public;

CREATE TYPE transfer_status as ENUM (
    'pending',
    'processing',
    'succeeded',
    'succeeded_with_warning',
    'error'
);

-- the request must contain at least the following keys: 
-- schema 
-- entity
-- payload
-- action

CREATE TABLE transfer(
	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    status transfer_status NOT NULL DEFAULT 'pending',
    request JSONB NOT NULL,
    result JSONB
);

-- todo: more generic
CREATE FUNCTION transfer_trigger() RETURNS TRIGGER AS $$
BEGIN 
    PERFORM pg_notify(NEW.request->>'schema', NEW.id::text); 
    
    --RAISE NOTICE NEW.request->>'schema';
    
    --CASE NEW.request->>'schema'
    --    WHEN 'core' THEN
    --        SELECT core.manager(NEW.id, NEW.request) INTO NEW.response;
    --    WHEN 'cms' THEN
    --       SELECT cms.manager(NEW.id, NEW.request) INTO NEW.response;
    --    ELSE
    --        RAISE EXCEPTION 'not a valid schema'
    --END CASE;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER transfer_before_trigger BEFORE INSERT ON transfer
    FOR EACH ROW EXECUTE PROCEDURE transfer_trigger();
