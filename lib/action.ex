defmodule Wiki.Action.Session do
  @moduledoc """
  This module provides a struct for holding private connection state and accumulated results.

  ## Fields

  - `result` - Map with recursively merged values from all requests made using this session.
  - `opts` - Keyword list with options to change behavior.
  """

  @type client :: Tesla.Client.t()
  @type options :: keyword
  @type result :: map

  @type t :: %__MODULE__{
          __client__: client,
          opts: options,
          result: result
        }

  defstruct __client__: nil,
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
    meta: :siteinfo,
    siprop: :statistics
  })
  |> (&(&1.result)).()
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
  |> IO.puts()
  ```

  Streaming results from multiple requests using continuation,

  ```elixir
  Wiki.Action.new("https://de.wikipedia.org/w/api.php")
  |> Wiki.Action.stream(%{
    action: :query,
    list: :recentchanges,
    rclimit: 5
  })
  |> Stream.take(10)
  |> Enum.flat_map(fn response -> response["query"]["recentchanges"] end)
  |> Enum.map(fn rc -> rc["timestamp"] <> " " <> rc["title"] end)
  |> IO.inspect()
  ```
  """

  alias Wiki.Action.Session

  @doc """
  Create a new client session

  ## Arguments

  - `url` - `api.php` endpoint for the wiki you will connect to.  For example, "https://en.wikipedia.org/w/api.php".
  - `opts` - Client configuration options,
    - `{:overwrite, true}` - When set, the results won't accumulate, instead they will reset and
    `session.result` will only reflect the output of the latest request in a chain.  This is
    required when following continuations using the same session object, and will be automatically
    enabled when using `Wiki.Action.stream`.
  """
  @spec new(String.t(), Session.options()) :: Session.t()
  def new(url, opts \\ []) do
    %Session{
      __client__:
        client([
          {Tesla.Middleware.BaseUrl, url}
        ]),
      opts: opts
    }
  end

  @doc """
  Make requests to authenticate a client session.  This should only be done using
  a [bot username and password](https://www.mediawiki.org/wiki/Manual:Bot_passwords),
  which can be created for any normal user account.

  ## Arguments

  - `session` - Base session pointing to a wiki.
  - `username` - Bot username, may be different than the final logged-in username.
  - `password` - Bot password.  Protect this string, it allows others to take on-wiki actions on your behalf.

  ## Return value

  Authenticated session object.
  """
  @spec authenticate(Session.t(), String.t(), String.t()) :: Session.t()
  def authenticate(session, username, password) do
    session
    |> get(%{
      action: :query,
      meta: :tokens,
      type: :login
    })
    |> (&post(&1, %{
          action: :login,
          lgname: username,
          lgpassword: password,
          lgtoken: &1.result["query"]["tokens"]["logintoken"]
        })).()
  end

  @doc """
  Make an API GET request

  ## Arguments

  - `session` - `Wiki.Action.Session` object.
  - `params` - Map of query parameters as atoms or strings.

  ## Return value

  Session object with its `.result` populated.
  """
  @spec get(Session.t(), map) :: Session.t()
  def get(session, params), do: request(session, :get, query: Map.to_list(normalize(params)))

  @doc """
  Make an API POST request.

  ## Arguments

  - `session` - `Wiki.Action.Session` object.  If credentials are required for this
  action, you should have created this object with the `authenticate/3` function.
  - `params` - Map of query parameters as atoms or strings.

  ## Return value

  Session object with a populated `:result` attribute.
  """
  @spec post(Session.t(), map) :: Session.t()
  def post(session, params), do: request(session, :post, body: normalize(params))

  @doc """
  Make a GET request and follow continuations until exhausted or the stream is closed.

  ## Arguments

  - `session` - `Wiki.Action.Session` object.
  - `params` - Map of query parameters as atoms or strings.

  ## Return value

  Enumerable `Stream`, where each returned chunk is a raw result map, possibly
  containing multiple records.  This corresponds to `session.result` from the other
  entry points.
  """
  @spec stream(Session.t(), map) :: Enumerable.t()
  def stream(session, params) do
    session1 = %Session{session | opts: Keyword.put_new(session.opts, :overwrite, true)}

    Stream.resource(
      fn -> {session1, :start} end,
      fn
        {prev, :start} ->
          do_stream_get(prev, params)

        {prev, :cont} ->
          case prev.result do
            %{"continue" => continue} -> do_stream_get(prev, Map.merge(params, continue))
            _ -> {:halt, nil}
          end
      end,
      fn _ -> nil end
    )
  end

  defp do_stream_get(session, params) do
    next = get(session, params)
    {[next.result], {next, :cont}}
  end

  @spec request(Session.t(), :get | :post, keyword) :: Session.t()
  defp request(session, method, opts) do
    opts = [opts: session.opts] ++ opts ++ [method: method]

    result = Tesla.request!(session.__client__, opts)

    %Session{
      __client__: session.__client__,
      result:
        if session.opts[:overwrite] do
          result.body
        else
          result.opts[:result]
        end,
      opts: result.opts
    }
  end

  @spec normalize(map) :: map
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

  @spec defaults(map) :: map
  defp defaults(params) do
    format = Map.get(params, :format, :json)
    Map.merge(params, %{format: format})
  end

  @spec normalize_value(term) :: String.t()
  defp normalize_value(value)

  defp normalize_value(value) when is_list(value), do: Enum.join(value, "|")

  defp normalize_value(value), do: value

  @spec client(list) :: Tesla.Client.t()
  defp client(extra) do
    middleware =
      extra ++
        [
          {Tesla.Middleware.Compression, format: "gzip"},
          Wiki.Tesla.Middleware.CookieJar,
          Tesla.Middleware.FormUrlencoded,
          {Tesla.Middleware.Headers,
           [
             {"user-agent", Application.get_env(:wiki_elixir, :user_agent)}
           ]},
          Tesla.Middleware.JSON,
          Wiki.Tesla.Middleware.CumulativeResult
          # Debugging only:
          # Tesla.Middleware.Logger
        ]

    Tesla.client(middleware)
  end
end

defmodule Wiki.Tesla.Middleware.CookieJar do
  @moduledoc false

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    cookie_header =
      case env.opts[:cookies] do
        nil -> []
        cookies -> [{"cookie", serialize_cookies(cookies)}]
      end

    env =
      env
      |> Tesla.put_headers(cookie_header)

    with {:ok, env} <- Tesla.run(env, next) do
      cookies =
        env
        |> Tesla.get_headers("set-cookie")
        |> extract_cookies()
        |> update_cookies(env.opts[:cookies])

      env =
        env
        |> Tesla.put_opt(:cookies, cookies)

      {:ok, env}
    end
  end

  @spec update_cookies(map, map) :: map
  defp update_cookies(new_cookies, old_cookies)

  defp update_cookies(new_cookies, nil), do: new_cookies

  defp update_cookies(new_cookies, old_cookies) do
    # TODO: Use a library conforming to RFC 6265, for example respecting expiry.
    Map.merge(old_cookies, new_cookies)
  end

  @spec extract_cookies(Keyword.t()) :: map
  defp extract_cookies(headers) do
    headers
    |> Enum.map(&SetCookie.parse/1)
    |> Enum.into(%{}, fn %{key: k, value: v} -> {k, v} end)
  end

  @spec serialize_cookies(map) :: String.t()
  defp serialize_cookies(cookies) do
    cookies
    |> Enum.map(fn {key, value} -> key <> "=" <> value end)
    |> Enum.join("; ")
  end
end

defmodule Wiki.Tesla.Middleware.CumulativeResult do
  @moduledoc false

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    with {:ok, env} <- Tesla.run(env, next) do
      {:ok,
       env
       |> Tesla.put_opt(:result, recursive_merge(env.opts[:result] || %{}, env.body))}
    end
  end

  @spec recursive_merge(map, map) :: map
  defp recursive_merge(%{} = v1, %{} = v2), do: Map.merge(v1, v2, &recursive_merge/3)

  # TODO: _key can be dropped
  @spec recursive_merge(String.t(), map | String.t(), map | String.t()) :: map
  defp recursive_merge(_key, v1, v2)

  defp recursive_merge(_key, %{} = v1, %{} = v2), do: recursive_merge(v1, v2)

  defp recursive_merge(_key, v1, v2) when is_list(v1) and is_list(v2), do: v1 ++ v2

  defp recursive_merge(_key, v1, v2) when v1 == v2, do: v1
end
