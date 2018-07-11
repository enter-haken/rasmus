defmodule Web.Router do
  use Plug.Router
  require Logger

  plug Plug.Logger 

  plug Plug.Static, 
    at: "/", 
    from: :rasmus

  plug :match
 
  # It is important that `Plug.Parsers` is placed before the `:dispatch` plug in
  # the pipeline, otherwise the matched clause route will not receive the parsed
  # body in its `Plug.Conn` argument when dispatched.
  #
  # `Plug.Parsers` can also be plugged between `:match` and `:dispatch` this 
  # means that `Plug.Parsers` will run only if there is a matching route. 
  # This can be useful to perform actions such as authentication
  # *before* parsing the body, which should only be parsed if a route matches
  # afterwards.
  #
  # https://github.com/elixir-plug/plug/blob/v1.6.1/lib/plug/router.ex#L95

  plug Plug.Parsers, parsers: [:json],
    pass:  ["application/json"],
    json_decoder: Jason

  plug :dispatch

  get "/" do
    conn
    |> send_file(200, "priv/static/index.html")
  end

  post "/api" do
    Logger.info("#{inspect(conn, pretty: true)}")

    { status, body } =
      case conn.body_params do
        %{ "name" => name } -> response_ok
        _ -> response_error
      end
    conn 
    |> send_resp(status, body)
  end

  match _ do
    conn
    |> send_resp(404, "not found")
  end

  defp response_ok, do: { 200, Jason.encode!(%{ response: "ok"})}
  defp response_error, do: { 422, Jason.encode!(%{ response: "error"})}

end

