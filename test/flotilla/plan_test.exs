defmodule Flotilla.PlanTest do
  use ExUnit.Case, async: true

  alias Flotilla.Plan

  describe "from_keyword/1 + validate/1" do
    test "builds and validates a simple plan" do
      plan =
        Plan.from_keyword(
          artefact: [type: :docker_image, ref: "myapp:1.0"],
          targets: [type: :kubernetes, context: "prod", name: "api"],
          strategy: :immediate
        )

      assert plan.strategy == :immediate
      assert length(plan.targets) == 1
      assert Plan.validate(plan) == :ok
    end

    test "rejects empty targets" do
      plan = %Plan{
        artefact: %Flotilla.Artefact{type: :docker_image, ref: "x:1"},
        targets: [],
        strategy: :immediate
      }

      assert {:error, errors} = Plan.validate(plan)
      assert Enum.any?(errors, &String.contains?(&1, "no targets"))
    end

    test "rejects invalid strategy" do
      plan = %Plan{
        artefact: %Flotilla.Artefact{type: :docker_image, ref: "x:1"},
        targets: [%Flotilla.Target{type: :bare_metal, host: "srv1"}],
        strategy: :bogus
      }

      assert {:error, errors} = Plan.validate(plan)
      assert Enum.any?(errors, &String.contains?(&1, "strategy"))
    end

    test "cascades target validation errors" do
      plan = %Plan{
        artefact: %Flotilla.Artefact{type: :docker_image, ref: "x:1"},
        targets: [%Flotilla.Target{type: :bare_metal, host: nil}],
        strategy: :immediate
      }

      assert {:error, errors} = Plan.validate(plan)
      assert Enum.any?(errors, &String.contains?(&1, "host"))
    end
  end

  describe "batches/1" do
    test "immediate strategy returns one batch" do
      targets = for i <- 1..3, do: %Flotilla.Target{type: :bare_metal, host: "h#{i}"}
      plan = %Flotilla.Plan{strategy: :immediate, targets: targets}

      batches = Plan.batches(plan)
      assert length(batches) == 1
      assert length(hd(batches)) == 3
    end

    test "rolling with batch_size 2 returns 2 batches for 3 targets" do
      targets = for i <- 1..3, do: %Flotilla.Target{type: :bare_metal, host: "h#{i}"}
      plan = %Flotilla.Plan{strategy: :rolling, targets: targets, batch_size: 2}

      batches = Plan.batches(plan)
      assert length(batches) == 2
      assert length(hd(batches)) == 2
      assert length(Enum.at(batches, 1)) == 1
    end

    test "canary returns first target alone, then rest" do
      targets = for i <- 1..3, do: %Flotilla.Target{type: :bare_metal, host: "h#{i}"}
      plan = %Flotilla.Plan{strategy: :canary, targets: targets}

      batches = Plan.batches(plan)
      assert length(batches) == 2
      assert length(hd(batches)) == 1
      assert length(Enum.at(batches, 1)) == 2
    end

    test "blue_green returns single batch with all targets" do
      targets = for i <- 1..3, do: %Flotilla.Target{type: :bare_metal, host: "h#{i}"}
      plan = %Flotilla.Plan{strategy: :blue_green, targets: targets}

      batches = Plan.batches(plan)
      assert length(batches) == 1
      assert length(hd(batches)) == 3
    end
  end
end
