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
    # TODO: Is there a way to use Elixir.MixProject.project()[:version]?
    Application.get_env(
      :wiki_elixir,
      :user_agent,
      "wiki_elixir/0.1.4 (spam@ludd.net)"
    )
  end
end
