defmodule Flotilla.Deploy do
  @moduledoc """
  Deploy orchestrator.

  Takes a `Flotilla.Plan`, validates it, and executes the deployment
  according to its strategy. Records state for status queries and
  rollback.

  ## State storage

  In-memory `Agent` for v1. In a future version, persist to disk or
  external store.

  ## Usage

      {:ok, deploy_id} = Flotilla.Deploy.run(plan)
      Flotilla.Deploy.status(deploy_id)  # => :running | :succeeded | :failed | :rolled_back
      Flotilla.Deploy.rollback(deploy_id)
  """

  @type id :: String.t()
  @type status :: :pending | :running | :succeeded | :failed | :rolled_back
  @type state :: %{
          plan: Flotilla.Plan.t(),
          status: status(),
          started_at: DateTime.t() | nil,
          finished_at: DateTime.t() | nil,
          results: %{String.t() => :ok | {:error, term()}},
          previous_deploy: id() | nil
        }

  @table :flotilla_deployments

  # ── Public API ───────────────────────────────────────────────────

  @doc """
  Runs the deployment plan.

  Returns `{:ok, deploy_id}` on success, `{:error, reason}` on validation
  failure or unhandled error.  The actual deployment runs in a separate
  process so this call returns immediately with the deploy id.
  """
  @spec run(Flotilla.Plan.t()) :: {:ok, id()} | {:error, term()}
  def run(%Flotilla.Plan{} = plan) do
    with :ok <- Flotilla.Plan.validate(plan) do
      deploy_id = generate_id()
      state = initial_state(plan)
      persist(deploy_id, state)
      spawn(fn -> execute(deploy_id, plan) end)
      {:ok, deploy_id}
    else
      {:error, _} = err -> err
    end
  end

  @doc """
  Returns the current status of a deploy.
  """
  @spec status(id()) :: status() | :unknown
  def status(deploy_id) do
    case fetch(deploy_id) do
      nil -> :unknown
      %{status: status} -> status
    end
  end

  @doc """
  Returns the full state of a deploy.
  """
  @spec info(id()) :: state() | nil
  def info(deploy_id), do: fetch(deploy_id)

  @doc """
  Lists all known deploys (newest first).
  """
  @spec list() :: [{id(), status()}]
  def list do
    ensure_table!()
    :ets.tab2list(@table)
    |> Enum.map(fn {id, %{status: status}} -> {id, status} end)
    |> Enum.sort_by(fn {id, _} -> id end, :desc)
  end

  @doc """
  Rolls back a deploy. For v1, this marks it rolled_back (no real
  reverse operation — depends on target type).
  """
  @spec rollback(id()) :: :ok | {:error, term()}
  def rollback(deploy_id) do
    case fetch(deploy_id) do
      nil -> {:error, :unknown_deploy}
      %{status: :succeeded} = state ->
        update(deploy_id, %{state | status: :rolled_back, finished_at: now()})
        :ok
      %{status: s} -> {:error, {:cannot_rollback, s}}
    end
  end

  # ── Execution ────────────────────────────────────────────────────

  defp execute(deploy_id, plan) do
    update(deploy_id, fn state -> %{state | status: :running, started_at: now()} end)

    batches = Flotilla.Plan.batches(plan)
    results = run_batches(plan, batches, %{})
    final_status = compute_final_status(results, plan)

    update(deploy_id, fn state ->
      %{state | status: final_status, results: results, finished_at: now()}
    end)
  end

  defp run_batches(_plan, [], acc), do: acc

  defp run_batches(plan, [batch | rest], acc) do
    batch_results =
      batch
      |> Enum.map(fn target ->
        target_id = Flotilla.Target.id(target)
        result = deploy_target(plan, target)
        {target_id, result}
      end)
      |> Map.new()

    all_ok = Enum.all?(batch_results, fn {_, v} -> v == :ok end)

    if all_ok or not plan.rollback_on_failure do
      run_batches(plan, rest, Map.merge(acc, batch_results))
    else
      Map.merge(acc, batch_results)
    end
  end

  defp deploy_target(_plan, _target) do
    # For v1: simulate. Real implementation dispatches to Target adapters.
    # Without trebejo/arrea loaded, we report :ok (deferred to iter-054+).
    :ok
  end

  defp compute_final_status(results, plan) do
    all_ok = Enum.all?(results, fn {_, v} -> v == :ok end)

    if all_ok do
      :succeeded
    else
      if plan.rollback_on_failure, do: :rolled_back, else: :failed
    end
  end

  # ── Storage ──────────────────────────────────────────────────────

  defp initial_state(plan) do
    %{
      plan: plan,
      status: :pending,
      started_at: nil,
      finished_at: nil,
      results: %{},
      previous_deploy: nil
    }
  end

  defp persist(deploy_id, state) do
    ensure_table!()
    :ets.insert(@table, {deploy_id, state})
  end

  defp fetch(deploy_id) do
    ensure_table!()
    case :ets.lookup(@table, deploy_id) do
      [{_, state}] -> state
      [] -> nil
    end
  end

  defp update(deploy_id, state_or_fun) do
    ensure_table!()
    new_state =
      case state_or_fun do
        %{} = state -> state
        fun when is_function(fun, 1) -> fun.(fetch(deploy_id))
      end

    :ets.insert(@table, {deploy_id, new_state})
  end

  defp ensure_table! do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
        :ok
      _ -> :ok
    end
  end

  defp generate_id do
    "deploy-#{:erlang.unique_integer([:positive])}"
  end

  defp now, do: DateTime.utc_now()
end
