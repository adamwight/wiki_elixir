defmodule Elixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :wiki_tools,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      #mod: {WikiRecentChangesFeed, []},
      mod: {WikiSSE, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:eventsource_ex, "~> 0.0.2"},
      {:feeder, "~> 2.3.0"},
      {:httpotion, "~> 3.1.0"},
      {:poison, "~> 4.0.1"}
    ]
  end
end
