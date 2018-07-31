defmodule RasmusApp do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  
  require Logger

  def start(_type, _args) do
    Logger.info("start rasmus application")
    credentials = Application.get_env(:rasmus, :pg_config) 
    
    # List all child processes to be supervised
    children = [
      { Core.Counter, credentials },
      { Core.Inbound, credentials },
      { Core.Manager, credentials },
      { Core.Entity.Graph, credentials },
      { Plug.Adapters.Cowboy2, scheme: :http, plug: Web.Router, options: [port: 8080, dispatch: dispatch_config()] }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rasmus.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch_config do 
    [
      {:_, [
        {"/websocket/", Web.Socket, []},
        {:_, Plug.Adapters.Cowboy2.Handler, {Web.Router, []}}
      ]}
    ]
  end
end
