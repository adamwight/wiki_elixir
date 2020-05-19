defmodule Wiki.Ores do
  # TODO:
  #  * Wrap models?
  #  * Chunk at 50 revisions per request.
  #  * Offer parallelism up to 4.

  @spec new(String.t()) :: Tesla.Client.t()
  def new(project) do
    url = Application.get_env(:wiki_elixir, :ores) <> project <> "/"
    client([
      {Tesla.Middleware.BaseUrl, url}
    ])
  end

  @spec request(Tesla.Client.t(), map()) :: map()
  def request(client, params) do
    response = Tesla.get!(client, "/", query: normalize(params))
    response.body
  end

  defp normalize(%{} = params), do: normalize(Map.to_list(params))

  defp normalize([{k, v} | tail]), do: [{k, normalize(v)} | normalize(tail)]

  defp normalize([]), do: []

  defp normalize(value) when is_list(value), do: Enum.join(value, "|")

  defp normalize(value), do: value

  @spec client(list()) :: Tesla.Client.t()
  defp client(extra) do
    middleware =
      extra ++
      [
        {Tesla.Middleware.Compression, format: "gzip"},
        {Tesla.Middleware.Headers,
          [
            {"user-agent", Application.get_env(:wiki_elixir, :user_agent)}
          ]},
        Tesla.Middleware.JSON
        # Debugging only:
        # Tesla.Middleware.Logger
      ]

    Tesla.client(middleware)
  end
end