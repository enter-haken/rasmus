SET search_path TO core,public;

CREATE FUNCTION privilege_manager(request JSONB) RETURNS JSONB AS $$
BEGIN
    RETURN '[]'::JSONB;
END
$$ LANGUAGE plpgsql;
