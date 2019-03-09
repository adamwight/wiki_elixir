defmodule EchoSse.MixProject do
  use Mix.Project

  def project do
    [
      app: :echo_sse,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {EchoSSE, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 4.0"},
      {:wiki_elixir, github: "adamwight/wiki_elixir"}
      # To use the local code:
      #{:wiki_elixir, path: "../../"}
    ]
  end
end
