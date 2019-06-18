defmodule WikiRest do
  @moduledoc """
  Access the [Wikimedia REST API](https://www.mediawiki.org/wiki/REST_API)
  """

  def pageviews_per_article(project, article) do
    pageviews_per_article(project, "all-access", "all-agents", article, "daily", default_start_day, today)
  end

  def pageviews_per_article(project, article, start, finish) do
    pageviews_per_article(project, "all-access", "all-agents", article, "daily", start, finish)
  end

  def pageviews_per_article(project, access, agent, article, granularity, start, finish) do
    "https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/#{project}/#{access}/#{agent}/#{article}/#{granularity}/#{start}/#{finish}"
    |> get_body
  end

  def pageviews_aggregate(project) do
    pageviews_aggregate(project, default_start_day, today)
  end

  def pageviews_aggregate(project, start, finish) do
    pageviews_aggregate(project, "all-access", "all-agents", "daily", start, finish)
  end

  def pageviews_aggregate(project, access, agent, granularity, start, finish) do
    "https://wikimedia.org/api/rest_v1/metrics/pageviews/aggregate/#{project}/#{access}/#{agent}/#{granularity}/#{start}/#{finish}"
    |> get_body
  end

  defp get_body(url) do
    url
    |> IO.inspect
    |> HTTPoison.get!
    |> extract_body
  end

  defp extract_body(response) do
    response.body
  end

  defp default_start_day() do
    Timex.today
    |> Timex.shift(days: -7)
    |> daystamp
  end

  defp today() do
    Timex.today |> daystamp
  end

  defp daystamp(datetime) do
    datetime |> Timex.format!("{YYYY}{0M}{0D}")
  end
end
