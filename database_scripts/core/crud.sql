SET search_path TO core,public;

-- 
-- gets the table colums for a given schema and entity
--
-- udt_schema for build in types is "pg_catalog"
-- custom types will be "core" at the moment
-- data_type for custom type will be "USER-DEFINED"
--
CREATE FUNCTION get_table_metadata(request JSONB) RETURNS JSONB AS $$
DECLARE
    table_metadata JSONB;
BEGIN
    SELECT array_to_json(array_agg(r)) INTO table_metadata FROM (SELECT 
        column_name, 
        column_default, 
        is_nullable, 
        data_type, 
        character_maximum_length,
        udt_name,
        udt_schema,
        CASE WHEN datetime_precision > 0 THEN true ELSE false END AS is_date_field
        FROM information_schema.columns WHERE 
            table_schema = (request->>'schema')::TEXT AND 
            table_name = (request->>'entity')) r;

    RETURN table_metadata;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_update_statement(raw_request JSONB) RETURNS TEXT AS $$
    import json

    def create_update_statement(col, value, metadata):
        current_column = next(x for x in metadata if x["column_name"] == col)

        if not current_column:
            return ""

        if current_column["udt_name"] in ["varchar","text"]:
            return "{} = '{}'".format(col,value)
            
        if current_column["udt_schema"] == "core":
            return "{} = '{}'::{}".format(col,value, current_column["udt_name"])

        return "{} = {}".format(col,value)

    request = json.loads(raw_request)

    if not "data" in request:
        plpy.error("data must not be empty for updating {}".format(request["entity"]))

    if not "id" in request["data"]:
        plpy.error("id must not be empty, when updating {}".format(request["entity"]))
        
    metadata = json.loads(plpy.execute(plpy.prepare("SELECT core.get_table_metadata($1)", ["jsonb"]), [raw_request])[0]["get_table_metadata"])

    sql = "UPDATE {}.{} SET ".format(request["schema"], request["entity"])
    sql += ", ".join([create_update_statement(k,v, metadata) for k,v in request["data"].items() if k != 'id'])
    sql += " WHERE id = '{}'::UUID".format(request["data"]["id"])

    return sql 
        
$$ LANGUAGE plpython3u;

