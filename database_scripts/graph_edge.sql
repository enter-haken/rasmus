SET search_path TO rasmus,public;

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
            PRIMARY KEY(id_first_{row},id_second_{row})
          );
        """.format(row=row)
        plpy.execute(sql)
      else:
        sql = """
          CREATE TABLE edge_{row}_{column}(
            id_{row} UUID NOT NULL REFERENCES {row}(id) ON DELETE CASCADE, 
            id_{column} UUID NOT NULL REFERENCES {column}(id) ON DELETE CASCADE, 
            weight INTEGER NOT NULL default 1,
            PRIMARY KEY(id_{row},id_{column})
          );
        """.format(row=row,column=column)
        plpy.execute(sql)

$$ LANGUAGE plpython3u;
