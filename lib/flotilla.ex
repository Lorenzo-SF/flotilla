defmodule Flotilla do
  @moduledoc """
  Flotilla — multi-target deployment orchestration.

  Deploy the same artefact (binary, docker image, release) to multiple
  targets with rollout strategies and health gates.

  ## Targets (v1)

    * `:bare_metal` — SSH + systemd service
    * `:docker` — single host or swarm
    * `:kubernetes` — kubectl apply

  ## Rollout strategies

    * `:immediate` — all targets in parallel
    * `:rolling` — N targets at a time (default N=1)
    * `:canary` — 10% traffic first, observe, then full
    * `:blue_green` — switch traffic atomically

  ## Usage

      plan = %Flotilla.Plan{
        artefact: %Flotilla.Artefact{type: :docker_image, ref: "myapp:1.2.3"},
        targets: [
          %Flotilla.Target{type: :bare_metal, host: "srv1.example.com"},
          %Flotilla.Target{type: :kubernetes, context: "prod"}
        ],
        strategy: :rolling
      }

      {:ok, deploy_id} = Flotilla.Deploy.run(plan)
      Flotilla.Deploy.status(deploy_id)
      Flotilla.Deploy.rollback(deploy_id)
  """

  alias Flotilla.{Artefact, Plan, Target, Deploy}

  @typedoc "A deployment plan struct."
  @type plan :: Plan.t()
  @typedoc "A deployment artefact."
  @type artefact :: Artefact.t()
  @typedoc "A deployment target."
  @type target :: Target.t()

  @doc """
  Returns true if Flotilla can run (system has ssh, kubectl, etc.).
  """
  @spec available?() :: boolean()
  def available? do
    Code.ensure_loaded?(Trebejo) and Code.ensure_loaded?(Arrea)
  end

  @doc """
  Convenience wrapper around `Flotilla.Deploy.run/1`.
  """
  @spec deploy(plan()) :: {:ok, Deploy.id()} | {:error, term()}
  def deploy(%Plan{} = plan), do: Deploy.run(plan)

  @doc """
  Convenience wrapper around `Flotilla.Deploy.status/1`.
  """
  @spec status(Deploy.id()) :: Deploy.status()
  def status(deploy_id), do: Deploy.status(deploy_id)

  @doc """
  Convenience wrapper around `Flotilla.Deploy.rollback/1`.
  """
  @spec rollback(Deploy.id()) :: :ok | {:error, term()}
  def rollback(deploy_id), do: Deploy.rollback(deploy_id)
end
