defmodule OGMate.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/joladev/og_mate"

  def project do
    [
      app: :og_mate,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "OGMate",
      description: "OG image generation for Elixir content sites.",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  def cli do
    [preferred_envs: [precommit: :test]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:image, "~> 0.67.0"},
      {:nimble_options, "~> 1.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40.2", only: :dev, runtime: false}
    ] ++ json_polyfill()
  end

  defp json_polyfill do
    if Code.ensure_loaded?(:json) do
      []
    else
      [{:json_polyfill, "~> 0.1"}]
    end
  end

  defp aliases do
    [
      precommit: [
        "compile --warnings-as-errors",
        "deps.unlock --unused",
        "format",
        "test",
        "credo --strict"
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib mix.exs README.md LICENSE guides)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "guides/getting_started.md", "LICENSE"],
      source_ref: "v#{@version}"
    ]
  end
end
