defmodule BackendWorker do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :listener)
  end

  def init(pg_config) do
    {:ok, pid} = Postgrex.Notifications.start_link(pg_config)
    {:ok, ref} = Postgrex.Notifications.listen(pid, "core")
    IO.puts("listening to changes for pid #{inspect(pid)}")

    {:ok, {pid, ref }}
  end

  def handle_info({:notification, pid, ref, "core", payload},_) do
    # NOTIFY response
    IO.inspect(payload)
    
    {:noreply, {pid, ref, payload}}
  end

  def handle_info(_, state) do
    IO.puts("unhandled info: #{inspect(state)}")
    {:noreply, state}
  end
end
