defmodule TrendStore do
  def init() do
    :ets.new(:trends, [:named_table, :public])
  end

  def insertArticle(title, last_week, this_week) do
    :ets.insert(:trends, {title, last_week, this_week})
  end

  def getArticles() do
    :ets.match(:trends, {:"$1", :"$2", :"$3"})
  end
end
