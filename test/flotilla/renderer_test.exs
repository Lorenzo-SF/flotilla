defmodule Flotilla.RendererTest do
  @moduledoc """
  Renderer tests — verify the VDOM → HTML conversion for the most common
  tags. We extract the rendered HTML as a string and check for substrings
  to keep tests resilient to whitespace / attribute ordering.

  These tests require Phoenix.LiveView (optional dep). They are tagged
  `:requires_live_view` and skipped if Phoenix.LiveView is not loaded —
  see `test/test_helper.exs`.
  """
  use ExUnit.Case, async: true

  @moduletag :requires_live_view

  alias Flotilla.Components
  alias Flotilla.Renderer

  test "renders a simple text node" do
    vdom = Components.text("hello")
    html = render_to_string(vdom)
    assert html =~ "<span"
    assert html =~ "hello"
    assert html =~ "</span>"
  end

  test "renders col with children" do
    vdom = Components.col([Components.text("a"), Components.text("b")])
    html = render_to_string(vdom)
    assert html =~ "<div"
    assert html =~ "flex flex-col"
    assert html =~ "a"
    assert html =~ "b"
  end

  test "button renders phx-click from msg" do
    vdom = Components.button("Save", msg: :save)
    html = render_to_string(vdom)
    assert html =~ "<button"
    assert html =~ "phx-click=\"save\""
    assert html =~ "Save"
  end

  test "button without msg does not have phx-click" do
    vdom = Components.button("Cancel")
    html = render_to_string(vdom)
    assert html =~ "<button"
    refute html =~ "phx-click"
  end

  test "input renders placeholder and phx-change" do
    vdom = Components.input(placeholder: "Search...", on_change: :query)
    html = render_to_string(vdom)
    assert html =~ "<input"
    assert html =~ "placeholder=\"Search...\""
    assert html =~ "phx-change=\"query\""
  end

  test "checkbox renders checked when set" do
    vdom = Components.checkbox(checked: true, on_change: :toggle)
    html = render_to_string(vdom)
    assert html =~ "checked=\"true\""
  end

  test "checkbox without checked omits the attribute" do
    vdom = Components.checkbox()
    html = render_to_string(vdom)
    refute html =~ "checked"
  end

  test "select renders options" do
    vdom = Components.select(["red", "green", "blue"], on_change: :color)
    html = render_to_string(vdom)
    assert html =~ "<select"
    assert html =~ "<option value=\"red\">red</option>"
    assert html =~ "<option value=\"green\">green</option>"
    assert html =~ "phx-change=\"color\""
  end

  test "select marks the current value as selected" do
    vdom = Components.select(["red", "green"], value: "green")
    html = render_to_string(vdom)
    assert html =~ "<option value=\"red\">red</option>"
    assert html =~ "<option value=\"green\" selected>green</option>"
  end

  test "table renders header row and body rows" do
    vdom =
      Components.table(
        [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}],
        columns: [:id, :name]
      )

    html = render_to_string(vdom)
    assert html =~ "<table"
    assert html =~ "<th>id</th>"
    assert html =~ "<th>name</th>"
    assert html =~ "<td>1</td>"
    assert html =~ "<td>Alice</td>"
    assert html =~ "<td>2</td>"
    assert html =~ "<td>Bob</td>"
  end

  test "heading respects level option" do
    vdom = Components.heading("Hi", level: 1)
    html = render_to_string(vdom)
    assert html =~ "<h1"
    assert html =~ "Hi"
  end

  test "heading with invalid level falls back to h2" do
    vdom = Components.heading("Hi", level: 99)
    html = render_to_string(vdom)
    assert html =~ "<h2"
  end

  test "badge applies tone class" do
    vdom = Components.badge("ok", tone: :success)
    html = render_to_string(vdom)
    assert html =~ "<span"
    assert html =~ "bg-green-100"
    assert html =~ "ok"
  end

  test "spinner is self-closing" do
    vdom = Components.spinner()
    html = render_to_string(vdom)
    assert html =~ "<div"
    assert html =~ "animate-spin"
    assert html =~ "aria-label=\"loading\""
  end

  test "empty/error render their messages" do
    assert render_to_string(Components.empty("Nothing here")) =~ "Nothing here"
    assert render_to_string(Components.error("Boom")) =~ "Boom"
  end

  test "html in text is escaped" do
    vdom = Components.text("<script>alert(1)</script>")
    html = render_to_string(vdom)
    refute html =~ "<script>"
    assert html =~ "&lt;script&gt;"
  end

  test "unknown tag still renders (with data-tag marker)" do
    vdom = {:weird_tag, [class: "x"], "hello"}
    html = render_to_string(vdom)
    assert html =~ "<div"
    assert html =~ "data-tag=\"weird_tag\""
    assert html =~ "hello"
  end

  test "deeply nested view renders" do
    vdom =
      Components.col([
        Components.row([
          Components.button("−", msg: :dec),
          Components.text("0"),
          Components.button("+", msg: :inc)
        ]),
        Components.spinner()
      ])

    html = render_to_string(vdom)
    assert html =~ "<div"
    assert html =~ "phx-click=\"dec\""
    assert html =~ "phx-click=\"inc\""
    assert html =~ "0"
    assert html =~ "animate-spin"
  end

  # ---------------------------------------------------------------------------

  # Render and extract the rendered string. The renderer returns a
  # `Phoenix.LiveView.LiveStruct` (a record); we don't load Phoenix here,
  # so the renderer returns the iodata tuple which we can flatten.
  defp render_to_string(vdom) do
    iodata = Renderer.to_heex(vdom)

    case iodata do
      %{__struct__: Phoenix.LiveView.LiveStruct} ->
        # LiveStruct is a private record — we use IO.iodata_to_binary on
        # its inner field. The simpler path: read the :static attribute.
        iodata
        |> Map.get(:static)
        |> List.wrap()
        |> IO.iodata_to_binary()

      {:safe, parts} ->
        IO.iodata_to_binary(parts)

      other when is_binary(other) ->
        other

      other when is_list(other) ->
        IO.iodata_to_binary(other)

      other ->
        raise "unexpected renderer output: #{inspect(other)}"
    end
  end
end
