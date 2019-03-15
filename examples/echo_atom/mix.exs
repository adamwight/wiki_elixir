defmodule EchoAtom.MixProject do
  use Mix.Project

  def project do
    [
      app: :echo_atom,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {EchoAtom, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:wiki_elixir, "~> 0.1"}
      # To use the local code:
      #{:wiki_elixir, path: "../../"}
    ]
  end
end