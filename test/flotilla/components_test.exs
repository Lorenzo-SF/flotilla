defmodule Flotilla.ComponentsTest do
  @moduledoc """
  Tests for `Flotilla.Components`. Pure data-construction tests — no
  Phoenix LiveView required.
  """
  use ExUnit.Case, async: true

  alias Flotilla.Components
  alias Flotilla.VDOM

  describe "containers" do
    test "col/2 wraps children in a :col tuple" do
      children = [Components.text("a"), Components.text("b")]
      assert {:col, [], ^children} = Components.col(children)
    end

    test "col/2 with opts" do
      assert Components.col([], class: "w-full") == {:col, [class: "w-full"], []}
    end

    test "row/2 wraps children in a :row tuple" do
      children = [Components.text("x")]
      assert Components.row(children) == {:row, [], children}
    end

    test "card/2 wraps children in a :card tuple" do
      assert Components.card([Components.text("hi")]) == {:card, [], [Components.text("hi")]}
    end
  end

  describe "text" do
    test "text/2" do
      assert Components.text("hello") == {:text, [], "hello"}
    end

    test "heading/2 with level" do
      assert Components.heading("Hi", level: 1) == {:heading, [level: 1], "Hi"}
    end

    test "badge/2 with tone" do
      assert Components.badge("ok", tone: :success) == {:badge, [tone: :success], "ok"}
    end
  end

  describe "controls" do
    test "button/2 with msg" do
      assert Components.button("Save", msg: :save) == {:button, [msg: :save], "Save"}
    end

    test "input/1" do
      assert Components.input(placeholder: "Search...") ==
               {:input, [placeholder: "Search..."], nil}
    end

    test "select/2 with options" do
      assert Components.select(["a", "b"]) == {:select, [], ["a", "b"]}
    end

    test "checkbox/1 with checked" do
      assert Components.checkbox(checked: true) == {:checkbox, [checked: true], nil}
    end
  end

  describe "data" do
    test "table/2 with columns" do
      rows = [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}]

      assert Components.table(rows, columns: [:id, :name]) ==
               {:table, [columns: [:id, :name]], rows}
    end

    test "list/2 with item function" do
      fun = fn item -> Components.text(item.name) end
      items = [%{name: "a"}, %{name: "b"}]
      assert Components.list(items, item: fun) == {:list, [item: fun], items}
    end

    test "key_value/2 with pairs" do
      pairs = [{"User", "alice"}]
      assert Components.key_value(pairs) == {:key_value, [], pairs}
    end
  end

  describe "states" do
    test "spinner/1" do
      assert Components.spinner() == {:spinner, [], nil}
    end

    test "empty/2 with message" do
      assert Components.empty("Nothing here") == {:empty, [], "Nothing here"}
    end

    test "error/2 with message" do
      assert Components.error("Boom") == {:error, [], "Boom"}
    end
  end

  describe "VDOM contract" do
    test "every component returns a 3-tuple" do
      vdoms = [
        Components.col([]),
        Components.row([]),
        Components.card([]),
        Components.divider(),
        Components.grid([]),
        Components.stack([]),
        Components.center(Components.text("a")),
        Components.segment([]),
        Components.sidebar([]),
        Components.text("a"),
        Components.heading("a"),
        Components.badge("a"),
        Components.label("a"),
        Components.code("a"),
        Components.pre("a"),
        Components.kbd("a"),
        Components.blockquote("a"),
        Components.link("a"),
        Components.icon(:check),
        Components.form([]),
        Components.field(Components.input()),
        Components.input(),
        Components.textarea("a"),
        Components.select([]),
        Components.checkbox(),
        Components.radio_group([]),
        Components.switch(),
        Components.slider(),
        Components.datepicker(),
        Components.submit("a"),
        Components.menu([]),
        Components.breadcrumb([]),
        Components.pagination(),
        Components.tabs(),
        Components.navbar([]),
        Components.stepper(),
        Components.table([]),
        Components.list([]),
        Components.key_value([]),
        Components.stat("L", "V"),
        Components.timeline([]),
        Components.avatar(nil),
        Components.tree([]),
        Components.spinner(),
        Components.empty("m"),
        Components.error("m"),
        Components.progress(0.5),
        Components.alert("m"),
        Components.toast("m"),
        Components.skeleton(),
        Components.notification("m")
      ]

      for vdom <- vdoms do
        assert VDOM.vdom?(vdom), "expected #{inspect(vdom)} to be a VDOM node"
        {tag, opts, content} = vdom
        assert is_atom(tag)
        assert is_list(opts)
        assert content != nil
      end
    end
  end
end
