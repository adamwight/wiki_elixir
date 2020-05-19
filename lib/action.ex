defmodule Wiki.Action.Session do
  @moduledoc """
  This module provides a struct for holding private connection state and accumulated results.

  ## Fields

  - `result` - Map with recursively merged values from all requests made using this session.
  - `opts` - Keyword list with options to change behavior.
  """

  @type client :: Tesla.Client.t()
  @type cookie :: binary()
  @type option :: {:overwrite, true}
  @type options :: [option()]
  @type result :: map()

  @type t :: %__MODULE__{
          __client__: client,
          __cookie__: cookie | nil,
          opts: options,
          result: result
        }

  defstruct __client__: nil,
            __cookie__: nil,
            opts: [],
            result: %{}
end

defmodule Wiki.Action do
  @moduledoc """
  Adapter to the MediaWiki [Action API](https://www.mediawiki.org/wiki/Special:MyLanguage/API:Main_page)

  Anonymous requests,

  ```elixir
  Wiki.Action.new("https://de.wikipedia.org/w/api.php")
  |> Wiki.Action.get(%{
    action: :query,
    format: :json,
    meta: :siteinfo,
    siprop: :statistics
  })
  |> IO.inspect()
  ```

  Commands can be pipelined to accumulate results and to hold authentication cookies,

  ```elixir
  Wiki.Action.new(
    Application.get_env(:wiki_elixir, :default_site_api)
  )
  |> Wiki.Action.authenticate(
    Application.get_env(:wiki_elixir, :username),
    Application.get_env(:wiki_elixir, :password)
  )
  |> Wiki.Action.get(%{
    action: :query,
    meta: :tokens,
    type: :csrf
  })
  |> (&Wiki.Action.post(&1, %{
    action: :edit,
    title: "Sandbox",
    assert: :user,
    token: &1.result["query"]["tokens"]["csrftoken"],
    appendtext: "~~~~ was here."
  })).()
  |> (&(&1.result)).()
  |> Jason.encode!(pretty: true)
  |> IO.puts
  ```

  Streaming results from multiple requests using continuation,

  ```elixir
  Wiki.Action.new("https://de.wikipedia.org/w/api.php")
  |> Wiki.Action.stream(%{
    action: :query,
    format: :json,
    list: :recentchanges,
    rclimit: 5
  })
  |> Stream.take(10)
  |> Enum.flat_map(fn response -> response["query"]["recentchanges"] end)
  |> Enum.map(fn rc -> rc["timestamp"] <> " " <> rc["title"] end)
  |> IO.inspect
  ```
  """

  alias Wiki.Action.Session

  def new(url, opts \\ []) do
    %Session{
      __client__:
        client([
          {Tesla.Middleware.BaseUrl, url}
        ]),
      opts: opts
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

  @spec stream(Session.t(), map()) :: Enumerable.t()
  def stream(session, params) do
    session1 = %Session{session | opts: Keyword.put_new(session.opts, :overwrite, true)}

    Stream.resource(
      fn -> get(session1, params) end,
      fn prev ->
        case prev.result do
          %{"continue" => continue} ->
            next = get(prev, Map.merge(params, continue))
            {[next.result], next}

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
      case session.__cookie__ do
        nil -> opts
        _ = cookie -> Keyword.put(opts, :headers, [{"cookie", cookie}])
      end

    response = Tesla.request!(session.__client__, opts)

    cookie_jar =
      response.headers
      |> extract_cookies()
      # TODO: Overwrite cookies when keys match.
      |> merge_stale_cookies(session.__cookie__)

    %Session{
      __client__: session.__client__,
      __cookie__: cookie_jar,
      opts: session.opts,
      result: case Keyword.get(session.opts, :overwrite) do
        true -> response.body
        _ -> recursive_merge(session.result, response.body)
      end
    }
  end

  defp recursive_merge(%{} = v1, %{} = v2), do: Map.merge(v1, v2, &recursive_merge/3)

  defp recursive_merge(_key, %{} = v1, %{} = v2), do: recursive_merge(v1, v2)

  defp recursive_merge(_key, v1, v2) when is_list(v1) and is_list(v2), do: v1 ++ v2

  defp recursive_merge(_key, v1, v2) when v1 == v2, do: v1

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
