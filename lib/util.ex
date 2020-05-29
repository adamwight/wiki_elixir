defmodule Wiki.Util do
  @moduledoc false

  def default_adapter do
    Application.get_env(:wiki_elixir, :tesla_adapter, Tesla.Adapter.Hackney)
  end

  def user_agent do
    Application.get_env(
      :wiki_elixir,
      :user_agent,
      "wiki_elixir/" <> Elixir.MixProject.project()[:version] <> " (spam@ludd.net)")
  end
end