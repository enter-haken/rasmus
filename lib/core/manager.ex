defmodule Core.Manager do
  use GenServer

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :manager)
  end

  @doc """
  start database connection
  """
  def init(pg_config) do
    {:ok, pid} = Postgrex.start_link(pg_config)
    IO.puts("#{__MODULE__} started.")
    {:ok, pid}
  end

 @doc false
 def handle_cast(transfer_id, state) do
    IO.puts(transfer_id)
    case Postgrex.query(state, "SELECT core.transfer_manager($1)", [transfer_id]) do
      {:ok, result} -> IO.puts("manager performed: #{inspect(result)}")
      {:error, %{postgres: %{message: error}}} -> IO.puts("error: #{inspect(error)}")
    end
    {:noreply, state }
  end

  @doc """
  Starts the corresponding database manager.
  """
  def perform(id) do
    GenServer.cast(:manager, id)
  end

end
