SET search_path TO core,public;

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
--     "nodes" : [{
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
--     }
--     ] 
--   }
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
