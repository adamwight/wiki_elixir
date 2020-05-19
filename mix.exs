defmodule Elixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :wiki_elixir,
      version: "0.1.2",
      elixir: "~> 1.8",
      elixirc_paths: ["lib", "contrib"],
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      package: package(),
      source_url: "https://gitlab.com/adamwight/wiki_elixir",
      docs: [
        extras: [
          "CHANGELOG.md",
          "README.md"
        ],
        main: "readme"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [
        :httpoison,
        :logger,
        :timex
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cookie, "~> 0.0"},
      {:dialyxir, "~> 1.0", runtime: false},
      {:ex_doc, "~> 0.0", only: :dev, runtime: false},
      {:gen_stage, "~> 1.0"},
      {:hackney, "~> 1.0"},
      {:httpoison, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:tesla, "~> 1.0"},
      {:timex, "~> 3.0"}
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
      links: %{"GitLab" => "https://gitlab.com/adamwight/wiki_elixir"}
    ]
  end
end
