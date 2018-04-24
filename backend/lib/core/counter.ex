defmodule Core.Counter do
  @moduledoc """
  Listen to `rasmus` transfer inserts.
  """
  use GenServer

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
    IO.puts("listening to changes for pid #{inspect(pid)}")

    {:ok, {pid, ref }}
  end

  @doc """
  Handles `core` notifications
  """
  def handle_info({:notification, pid, ref, "core", payload},_) do
    # NOTIFY response
    IO.inspect(payload)
    
    {:noreply, {pid, ref}}
  end

  @doc """
    handle all other messages send to #{__MODULE__}
  """
  def handle_info(_, state) do
    IO.puts("unhandled info: #{inspect(state)}")
    {:noreply, state}
  end
end
