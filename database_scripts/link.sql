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
    id_user UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
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
        -- WHEN 'get' THEN SELECT rasmus.link_get_manager(request) INTO manager_result;
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


