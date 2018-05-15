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
      #{:ok, result} -> Logger.debug("manager performed: #{inspect(result, pretty: true)}")
      {:ok, %{messages: messages}} -> 
        if Enum.any?(messages, fn(x) -> x.severity == "WARNING" end) do
          set_succeeded_with_warning_state(state, transfer_id)
          Logger.debug("manager succeded with warnings: #{
            inspect(
              %{ 
                notice: get_notice_messages(messages), 
                warning: get_warning_messages(messages)
              })
          }")
       else
          set_succeeded_state(state,transfer_id)
          Logger.debug("manager succeded:  #{
            inspect(
              %{ 
                notice: get_notice_messages(messages), 
              })
          }")
       end

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

  defp set_state(state, transfer_id, sql_function_name, state_name) do
    
    case Postgrex.query(state, "SELECT core.#{sql_function_name}($1)", [transfer_id]) do
      {:ok, _} -> Logger.debug("set state '#{state_name}' for #{transfer_id} succeeded")
      _ -> Logger.error("set state '#{state_name}' for #{transfer_id} failed")
    end
  end

  defp set_error_state(state, transfer_id), do: set_state(state, transfer_id, "set_error", "error")
  defp set_succeeded_state(state, transfer_id), do: set_state(state, transfer_id, "set_succeeded", "succeeded")
  defp set_succeeded_with_warning_state(state, transfer_id), do: set_state(state, transfer_id, "set_succeeded_with_warning", "succeeded_with_warning")
    
  defp get_messages(messages, severity) do
    messages 
      |> Enum.filter(fn(x) -> x.severity == severity end) 
      |> Enum.map(fn(x) -> x.message end)
  end

  defp get_warning_messages(messages), do: get_messages(messages, "WARNING") 
  defp get_notice_messages(messages), do: get_messages(messages, "NOTICE")

end
