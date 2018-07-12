defmodule Web.Router do
  use Plug.Router
  require Logger

  @actions ["add","update","get","delete"]
  @entities ["user","privilege","role","link","appointment","list"]

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

  # default route
  get "/" do
    conn
    |> send_file(200, "priv/static/index.html")
  end

  post "/api" do
    with {:ok, action} <- get_action_from(conn.body_params),
         {:ok, entity}  <- get_entity_from(conn.body_params),
         {:ok, data } <- get_data_from(conn.body_params) 
    do
      Logger.info("Got #{action} for #{entity} with #{inspect(data)}") 

      Core.Inbound.add(conn.body_params)

      conn
      |> send_resp(200, get_succeeded_response())
    else
      {:error, message} -> 
        Logger.warn("Got malformed request: #{message}") 

        conn
        |> send_resp(422, get_error_response(message))
    end
  end

  match _ do
    conn
    |> send_resp(404, "not found")
  end

  defp get_succeeded_response, do: Jason.encode!(%{ response: "ok"})
  defp get_error_response(error), do: Jason.encode!(%{ response: error})

  defp get_action_from(%{ "action" =>  action } = _body_params) do
    #case Enum.member?(["add","update","get","delete"], action) do
    case Enum.member?(@actions, action) do
      true -> {:ok, action }
      _ -> { :error, "Action '#{action}' is not valid. Valid actions are #{get_quoted(@actions)}"}
    end
  end

  defp get_action_from(_body_params), do: { :error, "action is missing. Valid actions are #{get_quoted(@actions)}" }

  defp get_entity_from(%{ "entity" => entity } = _body_params) do
    case Enum.member?(@entities, entity) do
      true -> {:ok, entity }
      _ -> { :error, "Entity '#{entity}' is not valid. Valid entities are #{get_quoted(@entities)}" }
    end
  end

  defp get_entity_from(_body_params), do: { :error, "entity is missing. Valid entities are #{get_quoted(@entities)}" }

  # todo: add additional validations for data field, like "id" and so on.
  defp get_data_from(%{"data" => data} = _body_params) when data != %{}, do: {:ok, data }
  defp get_data_from(%{"data" => data} = _body_params) when data == %{}, do: {:error, "data field must not be empty" }
  defp get_data_from(_body_params), do: {:error, "data field is missing" }

  defp get_quoted(strings) do
    strings
    |> Enum.map(fn(x) -> "\'#{x}\'" end)
    |> Enum.join(", ")
  end
  
end
