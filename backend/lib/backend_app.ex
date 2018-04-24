defmodule BackendApp do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    credentials = Application.get_env(:backend, :pg_config) 
    
    # List all child processes to be supervised
    children = [
      { BackendWorker, credentials },
      { InboundWorker, credentials }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Backend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
