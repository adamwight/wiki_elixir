defmodule Wiki.Rest.Pageviews do
  @moduledoc """
  Retrieve aggregate pageview counts for any Wikimedia project, https://wikimedia.org/api/rest_v1/#/Pageviews%20data
  """

  alias Wiki.Rest.Util

  @spec pageviews_per_article(String.t(), String.t()) :: map()
  def pageviews_per_article(project, article) do
    pageviews_per_article(
      project,
      "all-access",
      "all-agents",
      article,
      "daily",
      Util.default_start_day(),
      Util.today()
    )
  end

  @spec pageviews_per_article(String.t(), String.t(), String.t(), String.t()) :: map()
  def pageviews_per_article(project, article, start, finish) do
    pageviews_per_article(project, "all-access", "all-agents", article, "daily", start, finish)
  end

  @spec pageviews_per_article(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: map()
  def pageviews_per_article(project, access, agent, article, granularity, start, finish) do
    "#{Wiki.Rest.wikimedia_org()}/metrics/pageviews/per-article/#{project}/#{access}/#{agent}/#{
      Util.normalize_title(article)
    }/#{granularity}/#{start}/#{finish}"
    |> Util.get_body()
  end

  @spec pageviews_aggregate(String.t()) :: map()
  def pageviews_aggregate(project) do
    pageviews_aggregate(project, Util.default_start_day(), Util.today())
  end

  @spec pageviews_aggregate(String.t(), String.t(), String.t()) :: map()
  def pageviews_aggregate(project, start, finish) do
    pageviews_aggregate(project, "all-access", "all-agents", "daily", start, finish)
  end

  @spec pageviews_aggregate(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: map()
  def pageviews_aggregate(project, access, agent, granularity, start, finish) do
    "#{Wiki.Rest.wikimedia_org()}/metrics/pageviews/aggregate/#{project}/#{access}/#{agent}/#{
      granularity
    }/#{start}/#{finish}"
    |> Util.get_body()
  end

  @spec pageviews_top(String.t()) :: map()
  def pageviews_top(project) do
    today = Timex.today() |> Timex.shift(days: -1)

    pageviews_top(
      project,
      Timex.format!(today, "{YYYY}"),
      Timex.format!(today, "{0M}"),
      Timex.format!(today, "{0D}")
    )
  end

  @spec pageviews_top(String.t(), String.t(), String.t()) :: map()
  def pageviews_top(project, year, month) do
    pageviews_top(project, year, month, "all-days")
  end

  @spec pageviews_top(String.t(), String.t(), String.t(), String.t()) :: map()
  def pageviews_top(project, year, month, day) do
    pageviews_top(project, "all-access", year, month, day)
  end

  @spec pageviews_top(String.t(), String.t(), String.t(), String.t(), String.t()) :: map()
  def pageviews_top(project, access, year, month, day) do
    "#{Wiki.Rest.wikimedia_org()}/metrics/pageviews/top/#{project}/#{access}/#{year}/#{month}/#{
      day
    }"
    |> Util.get_body()
  end

  @spec pageviews_top_by_country(String.t()) :: map()
  def pageviews_top_by_country(project) do
    today = Timex.today() |> Timex.shift(months: -1)

    pageviews_top_by_country(
      project,
      Timex.format!(today, "{YYYY}"),
      Timex.format!(today, "{0M}")
    )
  end

  @spec pageviews_top_by_country(String.t(), String.t(), String.t()) :: map()
  def pageviews_top_by_country(project, year, month) do
    pageviews_top_by_country(project, "all-access", year, month)
  end

  @spec pageviews_top_by_country(String.t(), String.t(), String.t(), String.t()) :: map()
  def pageviews_top_by_country(project, access, year, month) do
    "#{Wiki.Rest.wikimedia_org()}/metrics/pageviews/top-by-country/#{project}/#{access}/#{year}/#{
      month
    }"
    |> Util.get_body()
  end
end
