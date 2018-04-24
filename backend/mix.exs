defmodule Backend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :backend,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {BackendApp, []}
    ]
  end

  defp deps do
    [
      # todo: move to version 1.6 when ready
      {:postgrex, git: "https://github.com/elixir-ecto/postgrex.git", branch: "master"},
      {:jason, "~> 1.0"}
    ]
  end
end
