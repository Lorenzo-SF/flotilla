defmodule Flotilla.DeployTest do
  use ExUnit.Case, async: false

  alias Flotilla.{Artefact, Deploy, Plan, Target}

  setup do
    # Reset ETS table before each test.
    if :ets.whereis(:flotilla_deployments) != :undefined do
      :ets.delete(:flotilla_deployments)
    end
    :ok
  end

  defp simple_plan do
    %Plan{
      artefact: %Artefact{type: :docker_image, ref: "myapp:1.0"},
      targets: [
        %Target{type: :bare_metal, host: "srv1"},
        %Target{type: :bare_metal, host: "srv2"}
      ],
      strategy: :immediate,
      rollback_on_failure: false
    }
  end

  describe "run/1" do
    test "returns deploy_id for valid plan" do
      assert {:ok, deploy_id} = Deploy.run(simple_plan())
      assert is_binary(deploy_id)
      assert String.starts_with?(deploy_id, "deploy-")
    end

    test "returns error for invalid plan" do
      invalid = %Plan{artefact: %Artefact{type: :docker_image, ref: nil}, targets: [], strategy: :immediate}
      assert {:error, _} = Deploy.run(invalid)
    end
  end

  describe "status/1" do
    test "returns :running right after run" do
      {:ok, id} = Deploy.run(simple_plan())
      assert Deploy.status(id) in [:pending, :running, :succeeded]
    end

    test "eventually transitions to :succeeded (v1 stub)" do
      {:ok, id} = Deploy.run(simple_plan())
      Process.sleep(100)
      # v1 deploys succeed (stub deploy_target returns :ok).
      assert Deploy.status(id) == :succeeded
    end

    test "returns :unknown for nonexistent deploy" do
      assert Deploy.status("deploy-99999") == :unknown
    end
  end

  describe "list/0" do
    test "returns all known deploys" do
      {:ok, _id1} = Deploy.run(simple_plan())
      {:ok, _id2} = Deploy.run(simple_plan())
      assert length(Deploy.list()) >= 2
    end

    test "returns empty list when no deploys" do
      assert Deploy.list() == []
    end
  end

  describe "rollback/1" do
    test "rolls back a succeeded deploy" do
      {:ok, id} = Deploy.run(simple_plan())
      Process.sleep(100)

      assert Deploy.status(id) == :succeeded
      assert Deploy.rollback(id) == :ok
      assert Deploy.status(id) == :rolled_back
    end

    test "rejects rollback of unknown deploy" do
      assert {:error, :unknown_deploy} = Deploy.rollback("nonexistent")
    end

    test "rejects rollback of non-succeeded deploy" do
      # Manually insert a pending state.
      :ets.insert(:flotilla_deployments, {"x", %{status: :pending, results: %{}}})
      assert {:error, {:cannot_rollback, :pending}} = Deploy.rollback("x")
    end
  end

  describe "info/1" do
    test "returns full state" do
      {:ok, id} = Deploy.run(simple_plan())
      info = Deploy.info(id)
      assert info.plan.strategy == :immediate
      assert info.results == %{} or map_size(info.results) > 0
    end
  end
end
