defmodule Wiki.Rest.Edits do
  alias Wiki.Rest.Util

  @spec edits_aggregate(String.t()) :: map()
  def edits_aggregate(project) do
    month_ago = Timex.today() |> Timex.shift(months: -1) |> Util.daystamp()
    edits_aggregate(project, month_ago, Util.today())
  end

  @spec edits_aggregate(String.t(), String.t(), String.t()) :: map()
  def edits_aggregate(project, start, finish) do
    edits_aggregate(project, "all-editor-types", "all-page-types", "daily", start, finish)
  end

  @spec edits_aggregate(String.t(), String.t(), String.t(), String.t(), String.t(), String.t()) ::
          map()
  def edits_aggregate(project, editor_type, page_type, granularity, start, finish) do
    "#{Wiki.Rest.wikimedia_org()}/metrics/edits/aggregate/#{project}/#{editor_type}/#{page_type}/#{
      granularity
    }/#{start}/#{finish}"
    |> Util.get_body()
  end
end
