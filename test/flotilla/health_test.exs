defmodule Flotilla.HealthTest do
  use ExUnit.Case, async: true

  alias Flotilla.Health

  describe "Spec.build/1" do
    test "builds an http spec" do
      spec = Health.build(type: :http, url: "https://x.com/health")
      assert spec.type == :http
      assert spec.url == "https://x.com/health"
      assert spec.expected_status == [200]
    end

    test "builds a tcp spec" do
      spec = Health.build(type: :tcp, host: "x.com", port: 80)
      assert spec.type == :tcp
      assert spec.host == "x.com"
      assert spec.port == 80
    end
  end

  describe "tcp_check/2" do
    @tag :network
    test "connects to a real tcp port" do
      spec = Health.build(type: :tcp, host: "example.com", port: 80)
      assert Health.run(spec, timeout_ms: 5_000) == :ok
    end
  end
end
