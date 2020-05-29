defmodule Elixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :wiki_elixir,
      version: "0.1.4",
      elixir: "~> 1.8",
      elixirc_paths: ~w(lib contrib),
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      package: package(),
      source_url: "https://gitlab.com/adamwight/wiki_elixir",
      dialyzer: [
        plt_add_apps: ~w(cookie gen_stage jason tesla)a,
        plt_core_path: "priv/plts/"
      ],
      docs: [
        extras: ~w(CHANGELOG.md README.md),
        main: "readme"
      ],
      preferred_cli_env: [coveralls: :test],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cookie, "~> 0.0"},
      {:credo, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:doctor, "~> 0.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      {:gen_stage, "~> 1.0"},
      {:git_hooks, "~> 0.0", only: [:dev, :test]},
      {:hackney, "~> 1.0"},
      {:httpoison, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:mox, "~> 0.5", only: :test},
      {:tesla, "~> 1.0"}
    ]
  end

  defp description do
    "Provides Elixir connectors to work with Wikipedia feeds."
  end

  defp package do
    [
      files: ~w(.formatter.exs contrib lib mix.exs *.md),
      name: :wiki_elixir,
      maintainers: ["adamwight"],
      licenses: ["GPLv3"],
      links: %{"GitLab" => "https://gitlab.com/adamwight/wiki_elixir"}
    ]
  end
end
