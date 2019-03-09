defmodule Elixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :wiki_elixir,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      #mod: {WikiRecentChangesFeed, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:eventsource_ex, "~> 0.0.2"},
      {:ex_doc, "~> 0.19"},
      {:feeder, "~> 2.3"},
      {:httpotion, "~> 3.1"}
    ]
  end

  defp package do
    [
      name: :wiki_elixir,
      maintainers: ["adamwight"],
      licenses: ["GPLv3"],
      links: %{"GitHub" => "https://github.com/adamwight/wiki_elixir"}
    ]
  end
end
