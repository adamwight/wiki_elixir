defmodule Wiki.Ores do
  @moduledoc """
  This module provides an adapter for the [ORES](https://www.mediawiki.org/wiki/ORES) scoring service.

  ## Examples

  ```elixir
  Wiki.Ores.new("enwiki")
  |> Wiki.Ores.request(%{
    models: ["damaging", "wp10"],
    revids: 456789
  })
  |> Jason.encode!(pretty: true)
  |> IO.puts()
  ```
  """

  alias Wiki.Util

  # TODO:
  #  * Wrap models?
  #  * Chunk at 50 revisions per request.
  #  * Offer parallelism up to 4.

  @doc """
  Create a new ORES client.

  ## Arguments

  - `project` - Short code for the wiki where your articles appear.  For example, "enwiki" for English Wikipedia.

  ## Return value

  Returns an opaque client object, which should be passed to `request/2`.
  """
  @spec new(String.t()) :: Tesla.Client.t()
  def new(project) do
    url = endpoint() <> project <> "/"

    client([
      {Tesla.Middleware.BaseUrl, url}
    ])
  end

  defp endpoint do
    Application.get_env(:wiki_elixir, :ores_endpoint, "https://ores.wikimedia.org/v3/scores/")
  end

  @doc """
  Make an ORES request.

  Don't request scores for more than 50 revisions per request.

  ## Arguments

  - `client` - Client object as returned by `new/1`.
  - `params` - Map of query string parameters,
    - `:models` - Learning models to query.  These vary per wiki, see the [support matrix](https://tools.wmflabs.org/ores-support-checklist/)
    for availability and to read about what each model is scoring.  Multiple models can be passed as a list, for example,
    `[:damaging, :wp10]`, or as a single atom, `:damaging`.
    - `:revids` - Revision IDs to score, as a single integer or as a list.
  """
  @spec request(Tesla.Client.t(), map) :: map
  def request(client, params) do
    response = Tesla.get!(client, "/", query: normalize(params))
    response.body
  end

  @spec normalize(map | Keyword.t()) :: Keyword.t()
  defp normalize(params)

  defp normalize(%{} = params), do: normalize(Map.to_list(params))

  defp normalize([{k, v} | tail]), do: [{k, normalize_value(v)} | normalize(tail)]

  defp normalize([]), do: []

  @spec normalize_value(String.t() | atom | [String.t() | atom]) :: String.t() | atom
  defp normalize_value(value)

  defp normalize_value(value) when is_list(value), do: Enum.join(value, "|")

  defp normalize_value(value), do: value

  @spec client(list) :: Tesla.Client.t()
  defp client(extra) do
    middleware =
      extra ++
        [
          {Tesla.Middleware.Compression, format: "gzip"},
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
