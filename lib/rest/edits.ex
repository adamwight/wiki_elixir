defmodule WikiRest.Edits do
  def edits_aggregate(project) do
    month_ago = Timex.today() |> Timex.shift(months: -1) |> daystamp
    edits_aggregate(project, month_ago, today())
  end

  def edits_aggregate(project, start, finish) do
    edits_aggregate(project, "all-editor-types", "all-page-types", "daily", start, finish)
  end

  def edits_aggregate(project, editor_type, page_type, granularity, start, finish) do
    "#{WikiRest.wikimedia_org}/metrics/edits/aggregate/#{project}/#{editor_type}/#{page_type}/#{granularity}/#{start}/#{finish}"
    |> WikiRest.Util.get_body
  end
end
