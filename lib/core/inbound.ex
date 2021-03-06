defmodule Core.Inbound do
  @moduledoc """
  Inserts core requests into `transfer`
  """
  use GenServer

  require Logger

  # genserver functions

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :inbound_worker)
  end

  @doc """
  start database connection
  """
  def init(pg_config) do
    {:ok, pid} = Postgrex.start_link(pg_config)
    Logger.info("#{__MODULE__} started.")

    {:ok, pid}
  end

  @doc """
  adds a new entity into the database 
  """
  def handle_cast({:add, payload}, state) do
    case Postgrex.query(state, "INSERT INTO rasmus.transfer (request) VALUES ($1)", [payload]) do
      {:ok, result} -> Logger.debug("added into transfer: #{inspect(result)}")
      {:error, error} -> Logger.error("adding into transfer failed: #{inspect(error)}. Tried to add #{inspect(payload)}")
    end
    {:noreply, state }
  end
  
  @doc """
  get one row from the transfer table.
  This will be removed
  """
  def handle_cast({:get}, state) do
    {:ok, result} = Postgrex.query(state, "SELECT * FROM rasmus.transfer LIMIT 1",[])

    Logger.debug("select one row from transfer: #{inspect(result)}")
    {:noreply, state}
  end
  
  def handle_info(_, state) do
    Logger.warn("unhandled info: #{inspect(state)}")
    {:noreply, state}
  end

  # client side functions
  def add(entity) do
    GenServer.cast(:inbound_worker, {:add, entity})
  end

  def get() do
    GenServer.cast(:inbound_worker, {:get})
  end

end
