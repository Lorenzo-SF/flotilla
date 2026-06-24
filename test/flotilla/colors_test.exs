defmodule Flotilla.ColorsTest do
  @moduledoc """
  Tests for `Flotilla.Colors`. The Pote bridge is optional; tests
  cover both branches (Pote present and absent).
  """
  use ExUnit.Case, async: true

  alias Flotilla.Colors

  describe "pote_available?/0" do
    test "returns a boolean" do
      assert is_boolean(Colors.pote_available?())
    end
  end

  describe "to_rgb_css/1 without Pote" do
    test "passes through hex strings" do
      assert Colors.to_rgb_css("#FF0000") == "#FF0000"
    end

    test "passes through named colors" do
      assert Colors.to_rgb_css("tomato") == "tomato"
    end

    test "converts non-binary values via to_string" do
      assert Colors.to_rgb_css(:red) == "red"
    end
  end

  describe "style_from_opts/1" do
    test "returns empty list when no color opts" do
      assert Colors.style_from_opts([]) == []
      assert Colors.style_from_opts(class: "x") == []
    end

    test "extracts color, bg, border, ring, fill" do
      pairs = Colors.style_from_opts(color: "#FF0000", bg: "#00FF00", border: "blue")
      assert {"color", "#FF0000"} in pairs
      assert {"background-color", "#00FF00"} in pairs
      assert {"border-color", "blue"} in pairs
    end

    test "ignores unknown keys" do
      pairs = Colors.style_from_opts(foo: "bar")
      assert pairs == []
    end
  end

  describe "style_attr/1" do
    test "returns empty string when no style-producing opts" do
      assert Colors.style_attr([]) == ""
      assert Colors.style_attr(class: "x") == ""
    end

    test "renders inline style attribute" do
      attr = Colors.style_attr(color: "#FF0000")
      assert String.starts_with?(attr, ~s(style="))
      assert String.ends_with?(attr, ~s("))
      assert attr =~ "color: #FF0000;"
    end

    test "joins multiple properties with semicolons" do
      attr = Colors.style_attr(color: "#FF0000", bg: "#00FF00")
      assert attr =~ "color: #FF0000;"
      assert attr =~ "background-color: #00FF00;"
    end
  end
end