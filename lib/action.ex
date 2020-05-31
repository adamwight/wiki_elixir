defmodule Wiki.Action.Session do
  @moduledoc """
  This module provides a struct for holding private connection state and accumulated results.

  ## Fields

  - `result` - Map with recursively merged values from all requests made using this session.
  - `state` - Cache for session state and accumulation.
  """

  @type client :: Tesla.Client.t()
  @type result :: map
  @type state :: keyword

  @type t :: %__MODULE__{
          __client__: client,
          result: result,
          state: keyword
        }

  defstruct __client__: nil,
            result: %{},
            state: []
end

defmodule Wiki.Action do
  @moduledoc """
  Adapter to the MediaWiki [Action API](https://www.mediawiki.org/wiki/Special:MyLanguage/API:Main_page)

  Anonymous requests,

  ```elixir
  Wiki.Action.new("https://de.wikipedia.org/w/api.php")
  |> Wiki.Action.get(
    action: :query,
    meta: :siteinfo,
    siprop: :statistics
  )
  |> (&(&1.result)).()
  |> IO.inspect()
  ```

  Commands can be pipelined while accumulating results, and logged-in user permissions
  delegated by supplying a [bot password](https://www.mediawiki.org/wiki/Manual:Bot_passwords).

  ```elixir
  Wiki.Action.new(
    "https://en.wikipedia.org/w/api.php",
    accumulate: true
  )
  |> Wiki.Action.authenticate(
    Application.get_env(:example_app, :bot_username),
    Application.get_env(:example_app, :bot_password)
  )
  |> Wiki.Action.get(
    action: :query,
    meta: :tokens,
    type: :csrf
  )
  |> (&Wiki.Action.post(&1, [{
    action: :edit,
    title: "Sandbox",
    assert: :user,
    token: &1.result["query"]["tokens"]["csrftoken"],
    appendtext: "~~~~ was here."
  ])).()
  |> (&(&1.result)).()
  |> Jason.encode!(pretty: true)
  |> IO.puts()
  ```

  Streaming results from multiple requests using continuation,

  ```elixir
  Wiki.Action.new("https://de.wikipedia.org/w/api.php")
  |> Wiki.Action.stream(
    action: :query,
    list: :recentchanges,
    rclimit: 5
  )
  |> Stream.take(10)
  |> Enum.flat_map(fn response -> response["query"]["recentchanges"] end)
  |> Enum.map(fn rc -> rc["timestamp"] <> " " <> rc["title"] end)
  |> IO.inspect()
  ```
  """

  alias Wiki.Action.Session
  alias Wiki.Util

  @doc """
  Create a new client session

  ## Arguments

  - `url` - `api.php` endpoint for the wiki you will connect to.  For example, "https://en.wikipedia.org/w/api.php".
  - `opts`
    - `:accumulate` - Merge results from each step of a pipeline, rather than overwriting with the latest response.
  """
  @spec new(String.t(), keyword) :: Session.t()
  def new(url, opts \\ []) do
    # TODO: This belongs in client/1, maybe pass options through?
    middleware =
      if opts[:accumulate] do
        [Wiki.StatefulClient.CumulativeResult]
      else
        []
      end ++
        [{Tesla.Middleware.BaseUrl, url}]

    %Session{
      __client__: client(middleware)
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
    |> get(
      action: :query,
      meta: :tokens,
      type: :login
    )
    |> (&post(&1,
          action: :login,
          lgname: username,
          lgpassword: password,
          lgtoken: &1.result["query"]["tokens"]["logintoken"]
        )).()
  end

  @doc """
  Make an API GET request

  ## Arguments

  - `session` - `Wiki.Action.Session` object.
  - `params` - Keyword list of query parameters as atoms or strings.
  - `opts` - Options to pass to the adapter.

  ## Return value

  Session object with its `.result` populated.
  """
  @spec get(Session.t(), keyword, keyword) :: Session.t()
  def get(session, params, opts \\ []),
    do: request(session, :get, opts ++ [query: normalize_params(params)])

  @doc """
  Make an API POST request.

  ## Arguments

  - `session` - `Wiki.Action.Session` object.  If credentials are required for this
  action, you should have created this object with the `authenticate/3` function.
  - `params` - Keyword list of query parameters as atoms or strings.
  - `opts` - Options to pass to the adapter.

  ## Return value

  Session object with a populated `:result` attribute.
  """
  @spec post(Session.t(), keyword, keyword) :: Session.t()
  def post(session, params, opts \\ []),
    do: request(session, :post, opts ++ [body: normalize_params(params)])

  @doc """
  Make a GET request and follow continuations until exhausted or the stream is closed.

  ## Arguments

  - `session` - `Wiki.Action.Session` object.
  - `params` - Keyword list of query parameters as atoms or strings.

  ## Return value

  Enumerable `Stream`, where each returned chunk is a raw result map, possibly
  containing multiple records.  This corresponds to `session.result` from the other
  entry points.
  """
  @spec stream(Session.t(), keyword) :: Enumerable.t()
  def stream(session, params) do
    Stream.resource(
      fn -> {session, :start} end,
      fn
        {prev, :start} ->
          do_stream_get(prev, params)

        {prev, :cont} ->
          case prev.result do
            %{"continue" => continue} -> do_stream_get(prev, params ++ Map.to_list(continue))
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
    # TODO: This can be extracted into a generic StatefulAdapter now.
    opts = [opts: session.state] ++ opts ++ [method: method]

    result = Tesla.request!(session.__client__, opts)

    %Session{
      __client__: session.__client__,
      result: result.body,
      state: Keyword.delete(result.opts, :opts)
    }
  end

  @spec normalize_params(keyword) :: keyword
  defp normalize_params(params) do
    ([format: :json] ++ params)
    |> remove_boolean_false()
    |> pipe_lists()
    |> Enum.sort()
    |> Enum.dedup()
  end

  defp remove_boolean_false(params) do
    params
    |> Enum.filter(fn {_, v} -> not (v in [false, nil]) end)
  end

  defp pipe_lists(params) do
    params
    |> Enum.map(fn
      {k, v} when is_list(v) -> {k, pipe_list(v)}
      entry -> entry
    end)
  end

  defp pipe_list(values) do
    if Enum.any?(values, fn v -> String.contains?(to_string(v), "|") end) do
      # Use a special join character because pipe would conflict with the value.
      unit_separator = "\x1f"
      Enum.join([""] ++ values, unit_separator)
    else
      Enum.join(values, "|")
    end
  end

  @spec client(list) :: Tesla.Client.t()
  defp client(extra) do
    middleware =
      extra ++
        [
          {Tesla.Middleware.Compression, format: "gzip"},
          Wiki.StatefulClient.CookieJar,
          Tesla.Middleware.FormUrlencoded,
          {Tesla.Middleware.Headers,
           [
             {"user-agent", Util.user_agent()}
           ]},
          Tesla.Middleware.JSON
          # Debugging only:
          # Tesla.Middleware.Logger
        ]

    Tesla.client(middleware, Util.default_adapter())
  end
end

defmodule Wiki.StatefulClient.CookieJar do
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

defmodule Wiki.StatefulClient.CumulativeResult do
  @moduledoc false

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    with {:ok, env} <- Tesla.run(env, next) do
      accumulated = recursive_merge(env.opts[:accumulated_result] || %{}, env.body)

      {:ok,
       Tesla.put_opt(env, :accumulated_result, accumulated)
       |> Tesla.put_body(accumulated)}
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
