defmodule Core.Entity.Graph do

  @moduledoc """
  gets the result for a graph from transfer 
  """
  use GenServer

  require Logger

  # genserver functions

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :graph)
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
  get one graph result from transfer
  """
  def handle_cast({:get, transfer_id}, state) do
    case Postgrex.query(state, "SELECT response FROM  rasmus.transfer WHERE id = $1", [UUID.string_to_binary!(transfer_id)]) do
      {:ok, result} -> Logger.debug("got response from transfer: #{inspect(result)}")
      {:error, error} -> Logger.error("getting response from transfer failed: #{inspect(error)}. Tried to get #{inspect(transfer_id)}")
    end
    {:noreply, state }
  end
  
  def handle_info(_, state) do
    Logger.warn("unhandled info: #{inspect(state)}")
    {:noreply, state}
  end

  # client side functions
  def get(transfer_id) do
    GenServer.cast(:graph, {:get, transfer_id})
  end

end
