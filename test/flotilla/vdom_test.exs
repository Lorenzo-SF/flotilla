defmodule Flotilla.VDOMTest do
  use ExUnit.Case, async: true

  alias Flotilla.VDOM

  test "node/3 builds a tuple" do
    assert VDOM.node(:text, [class: "x"], "hi") == {:text, [class: "x"], "hi"}
  end

  test "vdom?/1 recognises tagged tuples and rejects others" do
    assert VDOM.vdom?({:text, [], "x"})
    assert VDOM.vdom?({:col, [class: "x"], [{:text, [], "hi"}]})

    refute VDOM.vdom?({:text, "no list"})
    refute VDOM.vdom?("string")
    refute VDOM.vdom?(nil)
    refute VDOM.vdom?(42)
    refute VDOM.vdom?(:atom)
  end

  test "walk/2 visits every node depth-first" do
    tree =
      {:col, [],
       [
         {:text, [], "a"},
         {:row, [],
          [
            {:text, [], "b"},
            {:text, [], "c"}
          ]}
       ]}

    acc =
      VDOM.walk(tree, fn node -> send(self(), {:visited, node}) end)
      |> tap(fn _ -> :ok end)
      |> collect_visits(self(), [])

    tags = Enum.map(acc, fn {tag, _, _} -> tag end) |> Enum.sort()
    assert tags == [:col, :row, :text, :text, :text]
  end

  test "walk/2 with a leaf-only tree visits one node" do
    acc = VDOM.walk({:text, [], "hi"}, &send(self(), {:v, &1})) |> collect_visits(self(), [])
    assert length(acc) == 1
  end

  test "walk/2 handles nil children" do
    assert :ok == VDOM.walk({:spinner, [], nil}, fn _ -> :ok end)
  end

  # ---------------------------------------------------------------------------

  defp collect_visits(:ok, pid, acc) do
    flush(pid, acc)
  end

  defp flush(pid, acc) do
    receive do
      {:visited, node} -> flush(pid, [node | acc])
      {:v, node} -> flush(pid, [node | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end
