defmodule WikiRest.Pageviews do
  defmacro __using__(_) do
    quote do
      def pageviews_per_article(project, article) do
        pageviews_per_article(project, "all-access", "all-agents", article, "daily", default_start_day(), today())
      end

      def pageviews_per_article(project, article, start, finish) do
        pageviews_per_article(project, "all-access", "all-agents", article, "daily", start, finish)
      end

      def pageviews_per_article(project, access, agent, article, granularity, start, finish) do
        "#{@wikimedia_org}/metrics/pageviews/per-article/#{project}/#{access}/#{agent}/#{normalize_title(article)}/#{granularity}/#{start}/#{finish}"
        |> get_body
      end

      def pageviews_aggregate(project) do
        pageviews_aggregate(project, default_start_day(), today())
      end

      def pageviews_aggregate(project, start, finish) do
        pageviews_aggregate(project, "all-access", "all-agents", "daily", start, finish)
      end

      def pageviews_aggregate(project, access, agent, granularity, start, finish) do
        "#{@wikimedia_org}/metrics/pageviews/aggregate/#{project}/#{access}/#{agent}/#{granularity}/#{start}/#{finish}"
        |> get_body
      end

      def pageviews_top(project) do
        today = Timex.today() |> Timex.shift(days: -1)
        pageviews_top(project, Timex.format!(today, "{YYYY}"), Timex.format!(today, "{0M}"), Timex.format!(today, "{0D}"))
      end

      def pageviews_top(project, year, month) do
        pageviews_top(project, year, month, "all-days")
      end

      def pageviews_top(project, year, month, day) do
        pageviews_top(project, "all-access", year, month, day)
      end

      def pageviews_top(project, access, year, month, day) do
        "#{@wikimedia_org}/metrics/pageviews/top/#{project}/#{access}/#{year}/#{month}/#{day}"
        |> get_body
      end

      def pageviews_top_by_country(project) do
        today = Timex.today() |> Timex.shift(months: -1)
        pageviews_top_by_country(project, Timex.format!(today, "{YYYY}"), Timex.format!(today, "{0M}"))
      end

      def pageviews_top_by_country(project, year, month) do
        pageviews_top_by_country(project, "all-access", year, month)
      end

      def pageviews_top_by_country(project, access, year, month) do
        "#{@wikimedia_org}/metrics/pageviews/top-by-country/#{project}/#{access}/#{year}/#{month}"
        |> get_body
      end
    end
  end
end