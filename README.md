# Flotilla

> Declarative wrapper for Phoenix LiveView — model → update → view.

Flotilla lets you build LiveView UIs as composable data structures
following **The Elm Architecture** instead of writing HEEx templates
directly. All the state transitions, event handling, and rendering
happen in a single module you can read top-to-bottom.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)
[![Elixir](https://img.shields.io/badge/elixir-~%201.14-purple.svg)](mix.exs)

## Quick start

Add Flotilla and Phoenix LiveView to your app's `mix.exs`:

```elixir
def deps do
  [
    {:flotilla, "~> 0.1"},
    {:phoenix_live_view, "~> 1.0"}
  ]
end
```

Then define a LiveView:

```elixir
defmodule MyAppWeb.DashboardLive do
  use Flotilla.View

  @impl Flotilla.View.Behaviour
  def model(_params, _session, _socket) do
    %{count: 0, items: [], loading: false}
  end

  @impl Flotilla.View.Behaviour
  def update(:increment, model), do: %{model | count: model.count + 1}
  def update(:decrement, model), do: %{model | count: model.count - 1}
  def update({:set_items, items}, model), do: %{model | items: items, loading: false}
  def update(:load, model), do: %{model | loading: true}
  def update(_, model), do: model  # catch-all

  @impl Flotilla.View.Behaviour
  def view(model) do
    col([
      row([
        button("−", msg: :decrement),
        text("#{model.count}"),
        button("+", msg: :increment),
        button("Load", msg: :load)
      ]),
      if model.loading do
        spinner()
      else
        table(model.items, columns: [:id, :name, :status])
      end
    ])
  end
end
```

Wire it in your router as a regular LiveView:

```elixir
live "/dashboard", MyAppWeb.DashboardLive, :index
```

That's it — no template file, no separate `mount`, no `handle_event` boilerplate.

## How it works

```
        ┌─────────────────────────┐
        │  use Flotilla.View      │
        │  (macro)                │
        └─────────────┬───────────┘
                      │
                      ▼
   ┌──────────────────────────────────────┐
   │ Your module implements:              │
   │   model/3  →  initial state          │
   │   update/2 →  pure state transition  │
   │   view/1   →  VDOM tree              │
   └─────────────────┬────────────────────┘
                     │
                     ▼
   ┌──────────────────────────────────────┐
   │ Flotilla.View macro generates:       │
   │   mount/3         (calls model/3)    │
   │   handle_event/3  (calls update/2)  │
   │   render/1        (calls view/1 +    │
   │                    Renderer.to_heex) │
   └──────────────────────────────────────┘
```

## Components

| Container | `col`, `row`, `card` |
|---|---|
| **Text** | `text`, `heading`, `badge` |
| **Controls** | `button`, `input`, `select`, `checkbox` |
| **Data** | `table`, `list`, `key_value` |
| **States** | `spinner`, `empty`, `error` |

All helpers accept an `opts` keyword list; pass `:class` to override the
default Tailwind classes, `:msg` to wire `phx-click`, `:on_change` to
wire `phx-change`, etc.

## Why not just write HEEx?

- **State in one place**: model, transitions, and view live in a single
  module instead of being scattered across mount + handle_event + .heex.
- **Pure-function updates**: `update/2` is total and pure — easy to
  reason about, easy to test.
- **Composable views**: VDOM trees are just data. You can build a small
  helper that returns a vdom and call it from multiple views.
- **Static analysis**: Credo, Dialyzer and the type system understand
  your view function because it's Elixir code, not a templating language.

## Configuration

`Flotilla` is library-only — there's nothing to start in your supervision
tree. Just `use Flotilla.View` and you're set.

Optional dev dependencies (only used by `mix format` / `mix credo` /
`mix dialyzer`) are pulled in via the `mix.exs` `deps/0` function.

## License

MIT — see [LICENSE.md](LICENSE.md).

---

**For Spanish documentation, see [README_ES.md](README_ES.md).**
