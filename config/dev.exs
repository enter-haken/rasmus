use Mix.Config

config :rasmus, :pg_config, 
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "rasmus"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [
    :module
    #:function
  ] 
  #format: "$time [$level] $message\n"
  
