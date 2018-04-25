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
  After a request is inserted into `transfer`, the `Core.Manager.perform/1` is started
  """
  def handle_info({:notification, pid, ref, "core", payload},_) do
    IO.puts(payload)
    IO.inspect(Jason.decode(payload))
    case Jason.decode(payload) do
     {:ok , %{ "state" => "pending", "id" => id }} -> Core.Manager.perform(id)
      _ -> IO.puts("got unhandled notification: #{inspect(payload)}")
    end
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