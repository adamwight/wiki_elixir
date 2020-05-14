defmodule WikiRest.Util do
  @spec normalize_title(String.t()) :: String.t()
  def normalize_title(title) do
    title |> String.replace(" ", "_")
  end

  @spec get_body(String.t()) :: map()
  def get_body(url) do
    url
    |> HTTPoison.get!
    |> extract_body
  end

  @spec extract_body(HTTPoison.Response.t()) :: map()
  defp extract_body(response) do
    response.body
    |> Jason.decode!
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
end
