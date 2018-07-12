SET search_path TO rasmus,public;

-- todo: there must be exactly two foreign keys set for a valid edge

CREATE TABLE graph_edge(
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  id_person UUID REFERENCES person(id) ON DELETE CASCADE,
  id_appointment UUID REFERENCES appointment(id) ON DELETE CASCADE,
  id_list UUID REFERENCES list(id) ON DELETE CASCADE,
  id_link UUID REFERENCES "link"(id) ON DELETE CASCADE,
  weight INTEGER NOT NULL DEFAULT 1
);
