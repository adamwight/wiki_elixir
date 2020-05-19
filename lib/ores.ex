defmodule Wiki.Ores do
  # TODO:
  #  * Normalize lists of revids
  #  * Wrap models?

  def new(project) do
    url = Application.get_env(:wiki_elixir, :ores) <> project <> "/"
    client([
      {Tesla.Middleware.BaseUrl, url}
    ])
  end

  def request(client, params) do
    response = Tesla.get!(client, "/", query: Map.to_list(params))
    response.body
  end

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
        # Tesla.Middleware.Logger,
      ]

    Tesla.client(middleware)
  end
end