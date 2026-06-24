defmodule Flotilla.ColorsTest do
  use ExUnit.Case, async: true

  alias Flotilla.Colors

  describe "to_rgb_css/1 with Pote available" do
    test "converts hex strings to rgb(...)" do
      assert Colors.to_rgb_css("#FF0000") == "rgb(255, 0, 0)"
    end

    test "converts named colors to rgb(...)" do
      assert Colors.to_rgb_css("blue") == "rgb(0, 0, 255)"
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
      assert {"color", "rgb(255, 0, 0)"} in pairs
      assert {"background-color", "rgb(0, 255, 0)"} in pairs
      assert {"border-color", "rgb(0, 0, 255)"} in pairs
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
      assert attr =~ "color: rgb(255, 0, 0);"
    end

    test "joins multiple properties with semicolons" do
      attr = Colors.style_attr(color: "#FF0000", bg: "#00FF00")
      assert attr =~ "color: rgb(255, 0, 0);"
      assert attr =~ "background-color: rgb(0, 255, 0);"
    end
  end
end