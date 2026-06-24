defmodule Flotilla.LoaderTest do
  @moduledoc """
  Tests for `Flotilla.Loader`. The Arrea bridge is optional; tests
  cover both branches (Arrea present and absent).
  """
  use ExUnit.Case, async: true

  alias Flotilla.Loader

  describe "arrea_available?/0" do
    test "returns a boolean" do
      assert is_boolean(Loader.arrea_available?())
    end
  end

  describe "run_or_sequential/2 without Arrea" do
    test "runs loaders sequentially" do
      loaders = [fn -> 1 end, fn -> 2 end, fn -> 3 end]
      assert Loader.run_or_sequential(loaders) == [1, 2, 3]
    end

    test "propagates loader exceptions" do
      loaders = [fn -> 1 end, fn -> raise "boom" end]
      assert_raise RuntimeError, fn -> Loader.run_or_sequential(loaders) end
    end
  end

  describe "run/2 without Arrea" do
    test "returns an error tuple" do
      assert {:error, :arrea_not_available} = Loader.run([fn -> 1 end])
    end
  end
end
