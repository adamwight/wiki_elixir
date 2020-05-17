defmodule WikiAction do
  # TODO: More flexible endpoint.
  @default_endpoint Application.get_env(:wiki_elixir, :default_site_api)

  @spec get(Tesla.Client.t(), map()) :: map()
  def get(client, params), do: request(client, :get, query: Map.to_list(normalize(params)))

  @spec post(Tesla.Client.t(), map()) :: map()
  def post(client, params), do: request(client, :post, body: normalize(params))

  @spec normalize(map()) :: map()
  defp normalize(params) do
    params
    |> defaults()
    |> Enum.filter(fn {_, v} -> v != false end)
    |> Enum.map(fn {k, v} -> {k, normalize_value(v)} end)
    |> Enum.into(%{})
  end

  @spec defaults(map()) :: map()
  defp defaults(params) do
    format = Map.get(params, :format, :json)
    Map.merge(params, %{format: format})
  end

  @spec normalize_value(list()) :: String.t()
  defp normalize_value(value) when is_list(value), do: Enum.join(value, "|")

  @spec normalize_value(term()) :: String.t()
  defp normalize_value(value), do: value

  @spec request(Tesla.Client.t(), :get | :post, keyword()) :: map()
  defp request(client, method, opts) do
    {:ok, response} = Tesla.request(client, opts ++ [method: method])
    response.body
  end

  @spec stream(map()) :: Enumerable.t()
  def stream(params) do
    Stream.resource(
      fn -> get(client(), params) end,
      fn prev ->
        case prev do
          %{"continue" => continue} ->
            next = get(client(), Map.merge(params, continue))
            {[next], next}

          _ ->
            {:halt, nil}
        end
      end,
      fn _ -> nil end
    )
  end

  def authenticated_client(username, password) do
    # TODO:
    #  * Extract cookie saving into middleware?
    #  * Should be able to reuse internal request().
    {:ok, response} = Tesla.request(client(), method: :get, query: [
      action: :query,
      format: :json,
      meta: :tokens,
      type: :login
    ])
    login_token = response.body["query"]["tokens"]["logintoken"]
    cookie = Tesla.get_header(response, "set-cookie")
    client1 = client([
      {Tesla.Middleware.Headers, [{"cookie", cookie}]}
    ])

    {:ok, _} = Tesla.request(client1, method: :post, body: %{
      action: :login,
      format: :json,
      lgname: username,
      lgpassword: password,
      lgtoken: login_token
    })
    client1
  end

  @spec client(list()) :: Tesla.Client.t()
  defp client(extra \\ []) do
    middleware = extra ++ [
      {Tesla.Middleware.BaseUrl, @default_endpoint},
      {Tesla.Middleware.Compression, format: "gzip"},
      Tesla.Middleware.FormUrlencoded,
      {Tesla.Middleware.Headers, [
        {"user-agent", Application.get_env(:wiki_elixir, :user_agent)}
      ]},
      Tesla.Middleware.JSON,
      # Debugging only:
      # Tesla.Middleware.Logger,
    ]
    Tesla.client(middleware)
  end
end
