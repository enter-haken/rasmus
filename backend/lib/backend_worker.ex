defmodule BackendWorker do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(pg_config) do
    {:ok, pid} = Postgrex.Notifications.start_link(pg_config)
    {:ok, ref} = Postgrex.Notifications.listen(pid, "core")
    IO.puts("listening to changes")

    {:ok, {pid, ref }}
  end

  def handle_info({:notification, pid, ref, "core", payload},_) do
    IO.inspect(payload)
    
    {:noreply, {pid, ref, payload}}
  end

end
