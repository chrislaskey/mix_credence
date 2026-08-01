defmodule MixCredence.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_credence,
      version: "1.0.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A mix task wrapper for the credence semantic linter",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credence, ">= 0.0.0"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{}
    ]
  end
end
