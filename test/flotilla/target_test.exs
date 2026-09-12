defmodule Flotilla.TargetTest do
  use ExUnit.Case, async: true

  alias Flotilla.Target

  describe "from_keyword/1 + validate/1" do
    test "bare_metal needs host" do
      assert {:error, _} = Target.validate(%Target{type: :bare_metal, host: nil})
      assert :ok = Target.validate(%Target{type: :bare_metal, host: "srv1.example.com"})
    end

    test "kubernetes needs context" do
      assert {:error, _} = Target.validate(%Target{type: :kubernetes, context: nil})
      assert :ok = Target.validate(%Target{type: :kubernetes, context: "prod"})
    end

    test "docker needs host" do
      assert {:error, _} = Target.validate(%Target{type: :docker, host: nil})
      assert :ok = Target.validate(%Target{type: :docker, host: "swarm.example.com"})
    end

    test "rejects unknown type" do
      assert {:error, _} = Target.validate(%Target{type: :unknown})
    end
  end

  describe "id/1" do
    test "kubernetes target" do
      t = %Target{type: :kubernetes, context: "prod", name: "frontend"}
      assert Target.id(t) == "k8s:prod:frontend"
    end

    test "bare_metal target" do
      t = %Target{type: :bare_metal, host: "srv1", name: "api"}
      assert Target.id(t) == "bare_metal:srv1:api"
    end
  end
end
