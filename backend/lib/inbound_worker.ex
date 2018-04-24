defmodule InboundWorker do
  use GenServer

  # genserver functions
  
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :inbound_worker)
  end

  def init(pg_config) do
    {:ok, pid} = Postgrex.start_link(pg_config)
    IO.puts("InboundWorker started.")

    {:ok, pid}
  end

  def handle_cast({:add, payload}, state) do
    case Postgrex.query(state, "INSERT INTO core.transfer (request) VALUES ($1)", [payload]) do
      {:ok, result} -> IO.puts("add: #{inspect(result)}")
      {:error, %{postgres: %{message: error}}} -> IO.puts("error: #{inspect(error)}")
    end
    {:noreply, state }
  end

  # first tests getting data from database
  def handle_cast({:get}, state) do
    {:ok, result} = Postgrex.query(state, "SELECT * FROM core.transfer LIMIT 1",[])

    IO.puts("select: #{inspect(result)}")
    {:noreply, state}
  end
  
  def handle_info(_, state) do
    IO.puts("unhandled info: #{inspect(state)}")
    {:noreply, state}
  end

  # client side functions
  def add(entity) do
    GenServer.cast(:inbound_worker, {:add, entity})
  end

  def add() do
    # force db error
    add(%{"test" => 1})
    # first insert tests
    add(%{"entity" => "privilege", "payload" => %{"description" => "show dashboard", "name" => "dasboard", "role_level" => "guest"}, "schema" => "core"})
  end

  def get() do
    GenServer.cast(:inbound_worker, {:get})
  end

end
