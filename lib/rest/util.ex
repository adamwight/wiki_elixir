defmodule Wiki.Rest.Util do
  @spec normalize_title(String.t()) :: String.t()
  def normalize_title(title) do
    title |> String.replace(" ", "_")
  end

  @spec get_body(String.t()) :: map()
  def get_body(url) do
    client()
    |> Tesla.get!(url: url)
  end

  @spec default_start_day() :: String.t()
  def default_start_day() do
    Timex.today()
    |> Timex.shift(days: -7)
    |> daystamp
  end

  @spec today() :: String.t()
  def today() do
    Timex.today()
    |> daystamp
  end

  @spec daystamp(Date.t()) :: String.t()
  def daystamp(datetime) do
    datetime |> Timex.format!("{YYYY}{0M}{0D}")
  end

  @spec client() :: Tesla.Client.t()
  defp client() do
    middleware = [
      {Tesla.Middleware.Compression, format: "gzip"},
      {Tesla.Middleware.Headers,
       [
         {"user-agent", Application.get_env(:wiki_elixir, :user_agent)}
       ]},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware)
  end
end
