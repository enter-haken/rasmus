defmodule Core.Counter do
  @moduledoc """
  Listen to `rasmus` transfer inserts.
  """
  use GenServer

  require Logger

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :listener)
  end

  @doc """
  Starts postgres listener for the `core` channel
  """
  def init(pg_config) do
    {:ok, pid} = Postgrex.Notifications.start_link(pg_config)
    {:ok, ref} = Postgrex.Notifications.listen(pid, "core")
    
    Logger.info("#{__MODULE__} started.")
    Logger.info("listening to changes for pid #{inspect(pid)}")

    {:ok, {pid, ref }}
  end

  @doc """
  After a request is inserted into `transfer`, the `Core.Manager.perform/1` is started.
  """
  def handle_info({:notification, pid, ref, "core", payload},_) do
    case Jason.decode(payload) do
     {:ok , %{ "id" => id, "state" => "pending", }} -> Core.Manager.perform(id)
       
     {:ok , %{ "id" => id, "state" => state, "entity" => entity, "action" => action }} -> 
       Logger.debug("got a #{state} request for `#{action}` and `#{entity}` #{id}. ToDo: send message to processes using this entity.")

     {:ok , %{ "id" => id, "action" => "set_dirty", "entity" => entity }} -> 
       Logger.info("got `set_dirty` for `#{entity}` #{id}. ToDo: send message to processes using this entity.")

     _ -> Logger.warn("got unhandled notification: #{inspect(payload)}")
    end
    {:noreply, {pid, ref}}
  end

  @doc """
  handle all other messages send to #{__MODULE__}
  """
  def handle_info(_, state) do
    Logger.warn("unhandled info: #{inspect(state)}")
    {:noreply, state}
  end
end
