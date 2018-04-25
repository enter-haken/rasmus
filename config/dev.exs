use Mix.Config

config :rasmus, :pg_config, 
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "rasmus"

config :logger, 
  backends: [:console]
