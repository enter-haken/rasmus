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
    Logger.info("perform transfer_manager for transfer id: #{transfer_id}")
    case Postgrex.query(state, "SELECT core.transfer_manager($1)", [transfer_id]) do
      #{:ok, result} -> Logger.debug("manager performed: #{inspect(result)}")
      {:ok, %{messages: messages}} -> 
        Logger.debug("manager succeeded. pg_messages: #{inspect(Enum.map(messages,fn(x) -> x.message end))}")
        set_succeeded_state(state, transfer_id)

      {:error, %{postgres: %{code: :raise_exception, severity: "ERROR", message: message, hint: hint}}} -> 
        Logger.error("postgres EXCEPTION: #{message}, hint: #{hint}")
        set_error_state(state, transfer_id)

      {:error, %{postgres: %{code: :raise_exception, severity: "ERROR", message: message}}} -> 
        Logger.error("postgres EXCEPTION: #{message}")
        set_error_state(state, transfer_id)

      {:error, %{postgres: %{code: :undefined_function, severity: "ERROR", message: message}}} -> 
        Logger.error("postgres missing function EXCEPTION: #{message}")
        set_error_state(state, transfer_id)

      {:error,  error} -> Logger.error("error during executing transfer manager: #{inspect(error)}")
        set_error_state(state, transfer_id)
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

  defp set_error_state(state, transfer_id) do
    Postgrex.query(state, "SELECT core.set_error($1)", [transfer_id])
  end

  defp set_succeeded_state(state, transfer_id) do
    Postgrex.query(state, "SELECT core.set_succeeded($1)", [transfer_id])
  end

end
