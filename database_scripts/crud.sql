SET search_path TO rasmus,public;

-- 
-- gets the table columns for a given schema and entity
--
-- udt_schema for build in types is "pg_catalog"
-- custom types will be "rasmus" at the moment
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
            table_schema = 'rasmus' AND 
            table_name = (request->>'entity')) r;

    RETURN table_metadata;
END
$$ LANGUAGE plpgsql;

-- todo: exclude created_at, updated_at
CREATE FUNCTION get_update_statement(raw_request JSONB) RETURNS TEXT AS $$
    import json

    def create_update_statement(col, value, metadata):
        current_column = next(x for x in metadata if x["column_name"] == col)

        if not current_column:
            return ""

        if current_column["udt_name"] in ["varchar","text"]:
            return "{} = '{}'".format(col,value)
            
        if current_column["udt_schema"] == "rasmus":
            return "{} = '{}'::rasmus.{}".format(col,value, current_column["udt_name"])

        return "{} = {}".format(col,value)

    request = json.loads(raw_request)

    if not "data" in request:
        plpy.error("data must not be empty for updating {}".format(request["entity"]))

    if not "id" in request["data"] or not request["data"]["id"]:
        plpy.error("id must not be empty, when updating {}".format(request["entity"]))

    metadata = json.loads(plpy.execute(plpy.prepare(
                "SELECT rasmus.get_table_metadata($1)", ["jsonb"]), 
                [raw_request])[0]["get_table_metadata"])

    sql = "UPDATE rasmus.{} SET ".format(request["entity"])
    sql += ", ".join([x for x in [create_update_statement(k,v, metadata) for k,v in request["data"].items() if k != 'id'] if x])
    sql += " WHERE id = '{}'::UUID".format(request["data"]["id"])

    return sql 
$$ LANGUAGE plpython3u;

CREATE FUNCTION get_select_statement(raw_request JSONB, only_json_view BOOLEAN DEFAULT false) RETURNS TEXT AS $$
    import json

    def create_where_statement(col, value, metadata):
        current_column = next(x for x in metadata if x["column_name"] == col)

        # -- todo: array eg. WHERE x IN ['bla','blub']

        if not current_column:
            return ""

        # -- quoted text
        if current_column["udt_name"] in ["varchar","text"]:
            return "{} LIKE '%{}%'".format(col,value)
 
        # -- quoted uuid 
        if current_column["udt_name"] in ["uuid"]:
            return "{} = '{}'".format(col,value)
            
        # -- quoted enums:
        if current_column["udt_schema"] == "rasmus":
            return "{} = '{}'::rasmus.{}".format(col,value, current_column["udt_name"])

        return "{} = {}".format(col,value)

    request = json.loads(raw_request)
    
    metadata = json.loads(plpy.execute(plpy.prepare(
                "SELECT rasmus.get_table_metadata($1)", ["jsonb"]), 
                [raw_request])[0]["get_table_metadata"])

    sql = "SELECT "
    if only_json_view:
        # -- it is possible that the json view is null or dirty
        sql += "id, json_view"
    else:
        sql += ", ".join([x["column_name"] for x in metadata])

    sql += ' FROM rasmus.{}'.format(request["entity"])

    if "data" in request:
        sql += " WHERE "
        sql += " AND ".join([x for x in [create_where_statement(k,v, metadata) for k,v in request["data"].items()] if x])

    plpy.notice(sql)

    return sql

$$ LANGUAGE plpython3u;

CREATE FUNCTION flatten_json_view_response(raw_views JSONB) RETURNS JSONB AS $$
    import json

    response = [x["json_view"] for x in json.loads(raw_views) if x and x["json_view"]]
    
    return json.dumps(response)
$$ LANGUAGE plpython3u;

CREATE FUNCTION get_ids_for_empty_or_dirty_views(raw_views JSONB) RETURNS JSONB AS $$
    import json

    result = json.dumps([{ "id" : x["id"] } for x in json.loads(raw_views) if not x['json_view'] or x['json_view']['is_dirty']])
    return result;
$$ LANGUAGE plpython3u;

CREATE FUNCTION get_insert_statement(raw_request JSONB) RETURNS TEXT AS $$
    import json

    def create_value_statement(col, value, metadata):
        current_column = next(x for x in metadata if x["column_name"] == col)

        if not current_column:
            return ""

        if current_column["udt_name"] in ["varchar","text","uuid"]:
            return "'{}'".format(value)
            
        if current_column["udt_schema"] == "rasmus":
            return "'{}'::rasmus.{}".format(value, current_column["udt_name"])

        return value 

    request = json.loads(raw_request)

    if not "data" in request:
        plpy.error("data must not be empty for inserting {}".format(request["entity"]))

    # -- get all available columns
    metadata = json.loads(plpy.execute(plpy.prepare(
                "SELECT rasmus.get_table_metadata($1)", ["jsonb"]), 
                [raw_request])[0]["get_table_metadata"])
    
    sql = "INSERT INTO rasmus.{} (".format(request["entity"])
    sql += ", ".join(x for x in request["data"].keys() if x != "id")
    sql += ") VALUES ("
    sql += ", ".join([x for x in [create_value_statement(k,v,metadata) for k,v in request["data"].items() if k != "id"] if x])
    sql += ") RETURNING id;"

    plpy.notice(sql)

    return sql 
$$ LANGUAGE plpython3u;
