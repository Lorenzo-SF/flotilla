defmodule Flotilla.MixProject do
  @moduledoc """
  Mix project for Flotilla — multi-target deployment orchestration.

  Built on three companion libraries:
    * `arrea` — Async orchestration (workers, circuit breaker).
    * `trebejo` — Shell wrappers (ssh, docker, k8s, systemd).
    * `apero` — System utilities (env, conf, http, crypto).
  """

  use Mix.Project

  @version "0.1.0"
  @elixir_vsn "~> 1.19"

  def project do
    [
      app: :flotilla,
      version: @version,
      elixir: @elixir_vsn,
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Flotilla.CLI, name: "flotilla"]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl],
      mod: {Flotilla.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Optional path deps (compiles standalone if absent).
      {:arrea, path: "../arrea", optional: true, runtime: false},
      {:trebejo, path: "../trebejo", optional: true, runtime: false},
      {:apero, path: "../apero", optional: true, runtime: false},
      {:alaja, path: "../alaja", optional: true, runtime: false}
    ]
  end

  defp tools_version(_args) do
    "Mix and its tools are required for build."
  end
end
