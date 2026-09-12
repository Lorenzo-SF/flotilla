defmodule Flotilla.Plan do
  @moduledoc """
  A deployment plan describes what to deploy, where, and how.

  ## Example

      plan = %Flotilla.Plan{
        name: "release-1.2.3",
        artefact: %Flotilla.Artefact{
          type: :docker_image,
          ref: "myapp:1.2.3"
        },
        targets: [
          %Flotilla.Target{type: :kubernetes, context: "prod", name: "frontend"}
        ],
        strategy: :rolling,
        health_check: %Flotilla.Health.Spec{
          type: :http,
          url: "https://app.example.com/health"
        },
        rollback_on_failure: true
      }

      case Flotilla.Deploy.run(plan) do
        {:ok, deploy_id} -> IO.puts("Deploy \#{deploy_id} started")
        {:error, reason} -> IO.puts("Failed: \#{inspect(reason)}")
      end

  ## Strategies

    * `:immediate` — all targets in parallel.
    * `:rolling` — N targets at a time (default N=1).
    * `:canary` — one target first (canary), then rest if healthy.
    * `:blue_green` — deploy to "blue", then atomic switch.
  """

  defstruct [:name, :artefact, :targets, :strategy, :health_check, :rollback_on_failure, :batch_size, :metadata]

  @type strategy :: :immediate | :rolling | :canary | :blue_green

  @type t :: %__MODULE__{
          name: String.t() | nil,
          artefact: Flotilla.Artefact.t(),
          targets: [Flotilla.Target.t()],
          strategy: strategy(),
          health_check: Flotilla.Health.spec() | nil,
          rollback_on_failure: boolean(),
          batch_size: pos_integer(),
          metadata: map()
        }

  @doc """
  Builds a plan from keyword opts (convenience for tests/CLI).
  """
  @spec from_keyword(keyword()) :: t()
  def from_keyword(opts) do
    %__MODULE__{
      name: Keyword.get(opts, :name, "plan-#{System.unique_integer([:positive])}"),
      artefact: Flotilla.Artefact.from_keyword(Keyword.fetch!(opts, :artefact)),
      targets: Enum.map(Keyword.fetch!(opts, :targets), &Flotilla.Target.from_keyword/1),
      strategy: Keyword.get(opts, :strategy, :immediate),
      health_check: build_health(Keyword.get(opts, :health_check)),
      rollback_on_failure: Keyword.get(opts, :rollback_on_failure, true),
      batch_size: Keyword.get(opts, :batch_size, 1),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  defp build_health(nil), do: nil
  defp build_health(opts) when is_list(opts), do: Flotilla.Health.build(opts)

  @doc """
  Validates the plan.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(%__MODULE__{} = plan) do
    errors =
      []
      |> validate_artefact(plan)
      |> validate_targets(plan)
      |> validate_strategy(plan)

    case errors do
      [] -> :ok
      errs -> {:error, errs}
    end
  end

  defp validate_artefact(errors, %__MODULE__{artefact: art}) do
    case Flotilla.Artefact.validate(art) do
      :ok -> errors
      {:error, reason} -> ["artefact: #{reason}" | errors]
    end
  end

  defp validate_targets(errors, %__MODULE__{targets: []}) do
    ["plan has no targets" | errors]
  end

  defp validate_targets(errors, %__MODULE__{targets: targets}) do
    Enum.reduce(targets, errors, fn target, acc ->
      case Flotilla.Target.validate(target) do
        :ok -> acc
        {:error, reason} -> ["target #{Flotilla.Target.id(target)}: #{reason}" | acc]
      end
    end)
  end

  defp validate_strategy(errors, %__MODULE__{strategy: s})
       when s not in [:immediate, :rolling, :canary, :blue_green] do
    ["invalid strategy: #{inspect(s)}" | errors]
  end

  defp validate_strategy(errors, _), do: errors

  @doc """
  Partitions targets into batches for rolling deploys.
  """
  @spec batches(t()) :: [[Flotilla.Target.t()]]
  def batches(%__MODULE__{strategy: :immediate, targets: targets}), do: [targets]
  def batches(%__MODULE__{strategy: :canary, targets: [first | rest]}), do: [[first], rest]
  def batches(%__MODULE__{strategy: :canary, targets: []}), do: []
  def batches(%__MODULE__{strategy: :blue_green, targets: targets}), do: [targets]

  def batches(%__MODULE__{strategy: :rolling, targets: targets, batch_size: size}) do
    Enum.chunk_every(targets, max(size, 1))
  end
end
