defmodule Web.Router do
  use Plug.Router
  require Logger

  plug Plug.Logger 
  plug Plug.Static, 
    at: "/", 
    from: :rasmus

  plug :match
  plug :dispatch

  get "/test" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200,"done")
  end

  match _ do
    conn
    |> send_resp(404, "not found")
  end
  
  def start_link do
    {:ok, _} = Plug.Adapters.Cowboy.http(__MODULE__, [])
  end

end

