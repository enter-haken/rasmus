defmodule Rasmus.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rasmus,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :cowboy, :plug],
      mod: {RasmusApp, []}
    ]
  end

  defp deps do
    [
      # todo: move to version 1.6 when ready
      {:postgrex, git: "https://github.com/elixir-ecto/postgrex.git", branch: "master"},
      # used to cast UUID strings to binary representation for postgrex queries
      {:elixir_uuid, "~> 1.2"},
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.11", only: :dev, runtime: false},
      {:cowboy, "~> 2.4"},
      {:plug, "~> 1.4"}
    ]
  end
end
