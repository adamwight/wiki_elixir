defmodule Wiki.Util do
  @moduledoc false

  @doc false
  @spec default_adapter() :: atom
  def default_adapter do
    Application.get_env(:wiki_elixir, :tesla_adapter, Tesla.Adapter.Hackney)
  end

  @doc false
  @spec user_agent() :: String.t()
  def user_agent do
    Application.get_env(
      :wiki_elixir,
      :user_agent,
      "wiki_elixir/" <> Elixir.MixProject.project()[:version] <> " (spam@ludd.net)")
  end
end
