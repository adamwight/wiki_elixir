defmodule Wiki.Action.Session do
  @type client :: Tesla.Client.t()
  @type cookie :: binary()
  @type result :: map()

  @type t :: %__MODULE__{
          client: client,
          cookie: cookie | nil,
          result: result
        }

  defstruct client: nil,
            cookie: nil,
            result: %{}
end

defmodule Wiki.Action do
  alias Wiki.Action.Session

  def new(url) do
    %Session{
      client:
        client([
          {Tesla.Middleware.BaseUrl, url}
        ])
    }
  end

  @spec authenticate(Session.t(), String.t(), String.t()) :: Session.t()
  def authenticate(session, username, password) do
    session
    |> get(%{
      action: :query,
      format: :json,
      meta: :tokens,
      type: :login
    })
    |> (&post(&1, %{
          action: :login,
          format: :json,
          lgname: username,
          lgpassword: password,
          lgtoken: &1.result["query"]["tokens"]["logintoken"]
        })).()
  end

  @spec get(Session.t(), map()) :: map()
  def get(session, params), do: request(session, :get, query: Map.to_list(normalize(params)))

  @spec post(Session.t(), map()) :: map()
  def post(session, params), do: request(session, :post, body: normalize(params))

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

  @spec request(Session.t(), :get | :post, Keyword.t()) :: Session.t()
  defp request(session, method, opts) do
    opts = Keyword.put(opts, :method, method)

    opts =
      case session.cookie do
        nil -> opts
        _ -> Keyword.put(opts, :headers, [{"cookie", session.cookie}])
      end

    response = Tesla.request!(session.client, opts)

    cookie_jar =
      response.headers
      |> extract_cookies()
      # TODO: Overwrite cookies when keys match.
      |> merge_stale_cookies(session.cookie)

    %Session{
      client: session.client,
      cookie: cookie_jar,
      result: Map.merge(session.result, response.body)
    }
  end

  @spec normalize(map()) :: map()
  defp normalize(params) do
    params
    |> defaults()
    # Remove boolean false values entirely.
    |> Enum.filter(fn {_, v} -> v != false end)
    # Pipe-separated lists.
    |> Enum.map(fn {k, v} -> {k, normalize_value(v)} end)
    # Transform back into a map.
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

  @spec extract_cookies(Keyword.t()) :: String.t() | nil
  defp extract_cookies(headers) do
    headers
    |> get_headers("set-cookie")
    |> parse_cookies()
    |> repack_cookies()
    |> Cookie.serialize()
  end

  defp get_headers(headers, key) do
    for {k, v} <- headers, k == key, do: v
  end

  defp parse_cookies([]), do: []

  defp parse_cookies([header | others]), do: [SetCookie.parse(header) | parse_cookies(others)]

  defp repack_cookies(cookies) do
    for %{key: k, value: v} <- cookies, do: {k, v}
  end

  defp merge_stale_cookies(new_cookies, nil), do: new_cookies

  defp merge_stale_cookies(new_cookies, old_cookies) do
    new_cookies <> "; " <> old_cookies
  end

  @spec client(list()) :: Tesla.Client.t()
  defp client(extra \\ []) do
    middleware =
      extra ++
        [
          {Tesla.Middleware.Compression, format: "gzip"},
          Tesla.Middleware.FormUrlencoded,
          {Tesla.Middleware.Headers,
           [
             {"user-agent", Application.get_env(:wiki_elixir, :user_agent)}
           ]},
          Tesla.Middleware.JSON
          # Debugging only:
          # Tesla.Middleware.Logger,
        ]

    Tesla.client(middleware)
  end
end
