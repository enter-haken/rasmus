SET search_path TO rasmus,public;

-- there will be link types wich can have different behaviour / visualisations
-- eg. a link to a github / gitlab project
-- a link to reddit
-- 
-- todo: metadata
-- store additional metadata -> additional relations?

-- todo: json_view:
--
-- {
--   "metadata" : {
--     "current" : {
--       "id" : "blub",
--       "name" : "a",
--       "description" : "a",
--       "weight" : 1
--     },
--     "depth" : 1
--   },
--   "nodes" : [{
--       "id" : "blub",
--       "name" : "a",
--       "description" : "a",
--       "weight" : 1
--     },{
--       "id" : "bla",
--       "name" : "b",
--       "description" : "b",
--       "weight" : 1
--     },{
--       "id" : "blä",
--       "name" : "c",
--       "description" : "c",
--       "weight" : 1
--     }] 
--   },
--   "dot" : "graph { a - b; b - c; a -c; }"
-- }

-- todo: configuration
--
-- default depth for the graph: 1 ancestor
--
-- when the user zooms in and out there can exists multiple graphs
-- zooming feature is nothing more than increasing and decreasing the depth
-- every node in the whole graph can have different maximum distance to the edge.
-- one node on the edge will have the highest maximum distance on the graph

-- todo: multiple views
-- how to work with the dirty mechanism with multiple views?

-- todo: entities
-- there will be different entities like link, email, contact and so on
-- the graphs can contain multiple entities

CREATE TABLE "link"(
    id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    id_owner UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    name VARCHAR(80) UNIQUE NOT NULL,
    description VARCHAR(254),
    url VARCHAR(2048),
    json_view JSONB
);

--
-- manager functions
--

CREATE FUNCTION link_manager(request JSONB) RETURNS JSONB AS $$
DECLARE 
    link_response JSONB;
    manager_result JSONB;
BEGIN
    CASE request->>'action'
        WHEN 'get' THEN SELECT rasmus.link_get_manager(request) INTO manager_result;
        WHEN 'add' THEN SELECT rasmus.link_add_manager(request) INTO manager_result;
        -- WHEN 'delete' THEN SELECT rasmus.link_delete_manager(request) INTO manager_result;
        -- WHEN 'update' THEN SELECT rasmus.link_update_manager(request) INTO manager_result; 
        ELSE RAISE EXCEPTION 'unknown action `%`. aborting link manger', request->>'action';
    END CASE;

    link_response :=  rasmus.get_entity(request->>'entity')
        || jsonb_build_object('data', manager_result);

    RETURN link_response; 
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION link_get_manager(request JSONB) RETURNS JSONB AS $$
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
            PERFORM rasmus.get_link_view((dirty_id->>'id')::UUID);
        END LOOP;
        
        EXECUTE sql INTO response;
    END IF;
    
    SELECT rasmus.flatten_json_view_response(response) INTO response;

    RETURN response;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION link_add_manager(request JSONB) RETURNS JSONB AS $$
DECLARE 
    response JSONB;
    link_id UUID;
    sql TEXT;
BEGIN
    SELECT rasmus.get_insert_statement(request) INTO sql;

    EXECUTE sql INTO link_id;

    SELECT row_to_json(p) FROM (SELECT 
        id,
        name,
        description,
        url
        FROM rasmus."link"
        WHERE id = link_id) p INTO response;

    RETURN response;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_link_view(link_id UUID, dirty_read BOOLEAN DEFAULT false) RETURNS JSONB AS $$
DECLARE
    link_raw JSONB;
BEGIN
    IF dirty_read OR EXISTS (SELECT 1 FROM rasmus."link" WHERE 
            json_view IS NOT NULL AND 
            (json_view->>'is_dirty')::BOOLEAN = false AND 
            id = link_id) THEN
        SELECT json_view FROM rasmus."link" WHERE id = link_id INTO link_raw;
        RAISE NOTICE 'returning undirty link %', link_id;
        RETURN link_raw;
    END IF;

    -- todo: embed user
    SELECT row_to_json(link) FROM
      (SELECT id, id_owner, name, description, url FROM rasmus."link" WHERE id = link_id) "link" INTO link_raw;
  
    link_raw := link_raw
      || rasmus.get_entity('link');
  
    UPDATE rasmus."link" SET json_view = link_raw WHERE id = link_id;
    RAISE NOTICE 'update json_view for link %', link_id;
  
    RETURN link_raw;

END
$$ LANGUAGE plpgsql;

