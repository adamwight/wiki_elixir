defmodule TrendStore do
  use Agent

  def start_link(_opts) do
    :ets.new(:trends, [:named_table, :public])

    Agent.start_link(fn -> %{} end)
  end

  def insertArticle(title, last_week, this_week) do
    :ets.insert(:trends, {title, last_week, this_week})
  end

  def getArticles() do
    :ets.match(:trends, {:"$1", :"$2", :"$3"})
  end
end
