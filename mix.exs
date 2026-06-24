defmodule Flotilla.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Lorenzo-SF/flotilla"

  def project do
    [
      app: :flotilla,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp description do
    "Declarative wrapper for Phoenix LiveView - model → update → view, " <>
      "inspired by The Elm Architecture."
  end

  defp deps do
    [
      # Phoenix LiveView is OPTIONAL - only required if you actually use Flotilla
      # to render a LiveView. Library consumers can add it explicitly.
      {:phoenix_live_view, "~> 1.0", optional: true, only: :test},

      # Optional integrations used by Flotilla.Colors / Flotilla.Loader.
      # Loaded via Code.ensure_loaded?/2 so the library works without them.
      {:pote, "~> 1.0", optional: true},
      {:arrea, "~> 1.0", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "docs/README.es.md", "LICENSE.md"],
      maintainers: ["Lorenzo Sánchez"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "docs/README.es.md", "LICENSE.md", "CHANGELOG.md"],
      source_url: "https://github.com/Lorenzo-SF/flotilla",
      homepage_url: "https://github.com/Lorenzo-SF/flotilla",
      source_ref: "v0.1.0"
    ]
  end
end
