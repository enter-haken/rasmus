defmodule Web.Socket do
  @behaviour :cowboy_websocket

  require Logger

  def init(req, state) do
    Logger.info('#{inspect(__MODULE__)} initialized.')
    {:cowboy_websocket, req, state}
  end

  #Called on websocket connection initialization.
  def websocket_init(_state) do
    state = %{}
    {:ok, state}
  end

  # Handle 'ping' messages from the browser - reply
  def websocket_handle({:text, message}, state) do
    Logger.info('handle message #{inspect(message)}')
    {:reply, {:text, "pong"}, state}
  end
  
  # Format and forward elixir messages to client
  def websocket_info(_info, state) do
    {:reply, state} 
  end

  # No matter why we terminate, remove all of this pids subscriptions
  def websocket_terminate(_reason, _req, _state) do
    :ok
  end
end
