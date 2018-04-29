SET search_path TO core,public;

CREATE FUNCTION privilege_manager(request JSONB) RETURNS JSONB AS $$
DECLARE privilege_response JSONB;
BEGIN
    CASE request->>'action'
        WHEN 'get' THEN SELECT core.privilege_get_manager(request) INTO privilege_response;
        WHEN 'add' THEN RAISE EXCEPTION '% manager missing for %', request->>'action', request->>'entity';
        WHEN 'delete' THEN RAISE EXCEPTION '% manager missing for %', request->>'action', request->>'entity';
        WHEN 'update' THEN RAISE EXCEPTION '% manager missing for %', request->>'action', request->>'entity';
        ELSE RAISE EXCEPTION 'unknown action `%`. aborting privilege manger', request->>'action';
    END CASE;
    RETURN privilege_response; 
END
$$ LANGUAGE plpgsql;


CREATE FUNCTION privilege_get_manager(request JSONB) RETURNS JSONB AS $$
DECLARE
    response JSONB;
BEGIN
    IF request->'payload' IS NULL THEN
    SELECT array_to_json(array_agg(row_to_json(t)))
    FROM (
        SELECT id, 
            name, 
            description, 
            schema, 
            minimum_read_role_level, 
            minimum_write_role_level 
        FROM core.privilege) t
    INTO response;
    END IF;
    RETURN response;
END
$$ LANGUAGE plpgsql;
