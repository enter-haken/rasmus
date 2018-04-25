defmodule Core.Manager do
  use GenServer

  require Logger

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :manager)
  end

  @doc false
  def init(pg_config) do
    {:ok, pid} = Postgrex.start_link(pg_config)
    Logger.info("#{__MODULE__} started.")
    
    {:ok, pid}
  end

  @doc false
  def handle_cast(transfer_id, state) do
    Logger.info("perform manager for transfer id: #{transfer_id}")
    case Postgrex.query(state, "SELECT core.transfer_manager($1)", [transfer_id]) do
      {:ok, result} -> Logger.debug("manager performed: #{inspect(result)}")
      {:error, %{postgres: %{message: error}}} -> Logger.error("error during executing transfer manager: #{inspect(error)}")
    end
    {:noreply, state }
  end

  @doc """
  Starts the corresponding database manager.
  When the processing is finished the `response` column of the 
  corresponding `transfer` row is updated and a notification is send
  to the backend.
  """
  def perform(id) do
    GenServer.cast(:manager, id)
  end

end
