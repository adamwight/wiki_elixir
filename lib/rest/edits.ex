defmodule WikiRest.Edits do
  @spec edits_aggregate(String.t) :: String.t
  def edits_aggregate(project) do
    month_ago = Timex.today() |> Timex.shift(months: -1) |> WikiRest.Util.daystamp
    edits_aggregate(project, month_ago, today())
  end

  @spec edits_aggregate(String.t, String.t, String.t) :: String.t
  def edits_aggregate(project, start, finish) do
    edits_aggregate(project, "all-editor-types", "all-page-types", "daily", start, finish)
  end

  @spec edits_aggregate(String.t, String.t, String.t, String.t, String.t, String.t) :: String.t
  def edits_aggregate(project, editor_type, page_type, granularity, start, finish) do
    "#{WikiRest.wikimedia_org}/metrics/edits/aggregate/#{project}/#{editor_type}/#{page_type}/#{granularity}/#{start}/#{finish}"
    |> WikiRest.Util.get_body
  end
end
