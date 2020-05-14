defmodule Elixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :wiki_elixir,
      version: "0.1.1",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      package: package(),
      source_url: "https://gitlab.com/adamwight/wiki_elixir",
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [
        :timex
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", runtime: false},
      {:eventsource_ex, git: "https://github.com/cwc/eventsource_ex.git"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:feeder, "~> 2.3"},
      {:gen_stage, "~> 1.0"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},
      {:timex, "~> 3.6"}
    ]
  end

  defp description do
    "Provides Elixir connectors to work with Wikipedia feeds."
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
