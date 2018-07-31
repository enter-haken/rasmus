SET search_path TO rasmus,public;

-- this script creates the tables for adjacency lists 
-- every entity with a "json_view" column except "role" and "user"
-- can be used for the rasmus graph

DO $$
  # -- entities = ['link', 'person', 'appointment', 'list']

  entities = list(x["table_name"] for x in list(plpy.execute(""" SELECT table_name 
      FROM information_schema.columns 
      WHERE table_schema = 'rasmus' AND column_name = 'json_view' """)) 
    if x['table_name'] not in ["role","user"]) # -- exclude system views
  
  for row in entities:
    for column in entities:
      if (row == column):
        sql = """
CREATE TABLE edge_{row}_{row}(
  id_first_{row} UUID NOT NULL REFERENCES {row}(id) ON DELETE CASCADE, 
  id_second_{row} UUID NOT NULL REFERENCES {row}(id) ON DELETE CASCADE, 
  weight INTEGER NOT NULL default 1,
  label VARCHAR(128),
  json_view JSONB,
  PRIMARY KEY(id_first_{row},id_second_{row})
);

CREATE FUNCTION get_edge_{row}_{row}_view(first_id_{row} UUID, second_id_{row} UUID, dirty_read BOOLEAN DEFAULT false) 
  RETURNS JSONB AS {dollar}{dollar}
DECLARE
    edge_{row}_{row}_raw JSONB;
BEGIN
    IF dirty_read OR EXISTS (SELECT 1 FROM rasmus.edge_{row}_{row} WHERE 
            json_view IS NOT NULL AND 
            (json_view->>'is_dirty')::BOOLEAN = false AND 
            id_first_{row} = first_id_{row} AND id_second_{row} = second_id_{row}) THEN
        SELECT json_view FROM edge_{row}_{row} 
        WHERE id_first_{row} = first_id_{row} AND id_second_{row} = second_id_{row} INTO edge_{row}_{row}_raw;

        RAISE NOTICE 'returning undirty edge_{row}_{row} %,%', first_id_{row}, second_id_{row};
        RETURN edge_{row}_{row}_raw;
    END IF;

    SELECT row_to_json(x) FROM
      (SELECT id_first_{row}, id_second_{row}, weigth, label 
        FROM rasmus.edge_{row}_{row} 
        WHERE id_first_{row} = first_id_{row} AND id_second_{row} = second_id_{row}) x INTO edge_{row}_{row}_raw;
  
    edge_{row}_{row}_raw := edge_{row}_{row}_raw
      || rasmus.get_entity('edge_{row}_{row}');
  
    UPDATE rasmus.edge_{row}_{row} SET json_view =  edge_{row}_{row}_raw 
      WHERE id_first_{row} = first_id_{row} AND id_second_{row} = second_id_{row};

    RAISE NOTICE 'update json_view for edge_{row}_{row} %,%', first_id_{row}, second_id_{row};
  
    RETURN edge_{row}_{row}_raw;
END
{dollar}{dollar} LANGUAGE plpgsql;
        """.format(row=row, dollar="$")
        
        plpy.execute(sql)

      else:
        sql = """
CREATE TABLE edge_{row}_{column}(
  id_{row} UUID NOT NULL REFERENCES {row}(id) ON DELETE CASCADE, 
  id_{column} UUID NOT NULL REFERENCES {column}(id) ON DELETE CASCADE, 
  weight INTEGER NOT NULL default 1,
  label VARCHAR(128),
  PRIMARY KEY(id_{row},id_{column})
);

CREATE FUNCTION get_edge_{row}_{column}_view({row}_id UUID, {column}_id UUID, dirty_read BOOLEAN DEFAULT false) 
  RETURNS JSONB AS {dollar}{dollar}
DECLARE
    edge_{row}_{column}_raw JSONB;
BEGIN
    IF dirty_read OR EXISTS (SELECT 1 FROM rasmus.edge_{row}_{column} WHERE 
            json_view IS NOT NULL AND 
            (json_view->>'is_dirty')::BOOLEAN = false AND 
            id_{row} = {row}_id AND id_{column} = {column}_id) THEN
        SELECT json_view FROM edge_{row}_{column} 
        WHERE id_{row} = {row}_id AND id_{column} = {column}_id INTO edge_{row}_{column}_raw;

        RAISE NOTICE 'returning undirty edge_{row}_{column} and id_{row} %, id_{column} %', {row}_id, {column}_id;
        RETURN edge_{row}_{column}_raw;
    END IF;

    SELECT row_to_json(x) FROM
      (SELECT id_{row}, id_{column}, weigth, label 
        FROM rasmus.edge_{row}_{column} 
        WHERE id_{row} = {row}_id AND id_{column} = {column}_id) x INTO edge_{row}_{column}_raw;
  
    edge_{row}_{column}_raw := edge_{row}_{column}_raw
      || rasmus.get_entity('edge_{row}_{column}');
  
    UPDATE rasmus.edge_{row}_{column} SET json_view = edge_{row}_{column}_raw 
      WHERE id_{row} = {row}_id AND id_{column} = {column}_id;

    RAISE NOTICE 'update json_view for edge_{row}_{column} and id_{row} %, id_{column} %', {row}_id, {column}_id;

    RETURN edge_{row}_{column}_raw;
END
{dollar}{dollar} LANGUAGE plpgsql;
 

        """.format(row=row,column=column,dollar="$")
        plpy.execute(sql)

      sql = """
CREATE FUNCTION edge_{row}_{column}_manager(request JSONB) RETURNS JSONB AS {dollar}{dollar} 
DECLARE 
    {row}_{column}_response JSONB;
    manager_result JSONB;
BEGIN
    CASE request->>'action'
        WHEN 'get' THEN SELECT rasmus.edge_{row}_{column}_get_manager(request) INTO manager_result;
        -- WHEN 'add' THEN SELECT rasmus.edge_{row}_{column}_add_manager(request) INTO manager_result;
        -- WHEN 'delete' THEN SELECT rasmus.edge_{row}_{column}_delete_manager(request) INTO manager_result;
        -- WHEN 'update' THEN SELECT rasmus.edge_{row}_{column}_update_manager(request) INTO manager_result; 
        ELSE RAISE EXCEPTION 'unknown action `%`. aborting edge_{row}_{column} manger', request->>'action';
    END CASE;

    {row}_{column}_response :=  rasmus.get_entity(request->>'entity')
        || jsonb_build_object('data', manager_result);

    RETURN {row}_{column}_response; 
END
{dollar}{dollar} LANGUAGE plpgsql;

CREATE FUNCTION edge_{row}_{column}_get_manager(request JSONB) RETURNS JSONB AS {dollar}{dollar}
DECLARE
    response JSONB;
    sql TEXT;
    dirty_ids JSONB;
    dirty_id JSONB;
BEGIN
    -- select only json view
    SELECT rasmus.get_select_statement(request,true) INTO sql;

    sql := 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (' || sql || ') t';
    
    EXECUTE sql INTO response;

    SELECT rasmus.get_ids_for_empty_or_dirty_views(response) INTO dirty_ids;
    
    IF FOUND THEN
        RAISE NOTICE 'dirty or empty ids for %: %', request->>'entity',dirty_ids;

        FOR dirty_id in SELECT * FROM jsonb_array_elements(dirty_ids)
        LOOP
            PERFORM rasmus.get_{row}_{column}_view((dirty_id->>'id')::UUID);
        END LOOP;
        
        EXECUTE sql INTO response;
    END IF;
    
    SELECT rasmus.flatten_json_view_response(response) INTO response;

    RETURN response;
END
{dollar}{dollar} LANGUAGE plpgsql;

      """.format(row=row,column=column,dollar="$")
      plpy.execute(sql)

$$ LANGUAGE plpython3u;

-- <script type="text/javascript">
--   // create an array with nodes
--   var nodes = new vis.DataSet([
--     {id: 1, label: 'Node 1'},
--     {id: 2, label: 'Node 2'},
--     {id: 3, label: 'Node 3'},
--     {id: 4, label: 'Node 4'},
--     {id: 5, label: 'Node 5'}
--   ]);
-- 
--   // create an array with edges
--   var edges = new vis.DataSet([
--     {from: 1, to: 3},
--     {from: 1, to: 2},
--     {from: 2, to: 4},
--     {from: 2, to: 5},
--     {from: 3, to: 3}
--   ]);
-- 
--   // create a network
--   var container = document.getElementById('mynetwork');
--   var data = {
--     nodes: nodes,
--     edges: edges
--   };
--   var options = {};
--   var network = new vis.Network(container, data, options);
-- </script>


CREATE FUNCTION get_graph_for(raw_request JSONB) RETURNS JSONB AS $$
  import json

  request = json.loads(raw_request)

  link_request = json.dumps({
    "entity" : "link",
    "action" : "get",
    "data" : {
      "id_owner" : request["data"]["id_owner"] 
    }
  })

  links = json.loads(plpy.execute(plpy.prepare(
      "SELECT rasmus.link_get_manager($1)",["jsonb"]), [link_request])[0]["link_get_manager"])

  # -- todo: select all links where first link or second link in list of links from links dictionary ids
  edges = json.loads(plpy.execute(plpy.prepare(
      "SELECT rasmus.edge_link_link_get_manager($1)",["jsonb"]), [link_request])[0]["edge_link_link_get_manager"])
  
  response = {
    "owner" : request["data"]["id_owner"],
    "nodes" : links,
    "edges": edges
  } 

  return json.dumps(response) 

$$ LANGUAGE plpython3u

