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

That's it — no template file, no separate `mount`, no `handle_event`
boilerplate.

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

Flotilla ships **47+ ready-to-use components** organised by purpose.
Every helper returns a 3-tuple VDOM node that `Flotilla.Renderer`
turns into HEEx. All helpers accept an `opts` keyword list; pass
`:class` to override the default Tailwind classes, `:msg` to wire
`phx-click`, `:on_change` to wire `phx-change`, etc.

### Containers

| Helper | Notes |
|---|---|
| `col(children, opts \\ [])` | flex column |
| `row(children, opts \\ [])` | flex row |
| `card(children, opts \\ [])` | bordered with padding |
| `divider(opts \\ [])` | horizontal rule; pass `:label` for labelled divider |
| `grid(children, opts \\ [])` | CSS grid (`:cols:`, `:gap:`) |
| `stack(children, opts \\ [])` | vertical stack with consistent gap |
| `center(child, opts \\ [])` | centred single child |
| `segment(children, opts \\ [])` | Semantic UI style section |
| `sidebar(children, opts \\ [])` | fixed-width side panel |

### Text

| Helper | Notes |
|---|---|
| `text(content, opts \\ [])` | plain text |
| `heading(content, opts \\ [])` | `:level` 1..6 |
| `badge(content, opts \\ [])` | `:tone` (`:success` / `:warning` / `:error` / `:info` / `:neutral`) |
| `label(content, opts \\ [])` | form label |
| `code(content, opts \\ [])` | inline `<code>` |
| `pre(content, opts \\ [])` | multi-line block |
| `kbd(content, opts \\ [])` | keyboard key |
| `blockquote(content, opts \\ [])` | `:cite` for source |
| `link(label, opts \\ [])` | `:to`, `:msg` |
| `icon(name, opts \\ [])` | `:name` atom (`:check`, `:arrow_right`, ...) |

### Forms

| Helper | Notes |
|---|---|
| `form(children, opts \\ [])` | `:on_submit`, `:method`, `:action` |
| `field(child, opts \\ [])` | `:label`, `:hint`, `:error` |
| `input(opts \\ [])` | `:placeholder`, `:value`, `:on_change`, `:type` |
| `textarea(content, opts \\ [])` | multi-line input |
| `select(options, opts \\ [])` | strings or `{label, value}` tuples |
| `checkbox(opts \\ [])` | `:checked`, `:on_change` |
| `radio_group(options, opts \\ [])` | `:value`, `:on_change` |
| `switch(opts \\ [])` | toggle on/off |
| `slider(opts \\ [])` | `:min`, `:max`, `:value`, `:step` |
| `datepicker(opts \\ [])` | `:value` (`Date.t()`), `:on_change` |
| `submit(label, opts \\ [])` | submits the enclosing form |

### Navigation

| Helper | Notes |
|---|---|
| `menu(children, opts \\ [])` | horizontal/vertical (`:orientation`) |
| `breadcrumb(items, opts \\ [])` | trail of links |
| `pagination(opts \\ [])` | `:current_page`, `:total_pages`, `:on_change` |
| `tabs(opts \\ [])` | `:tabs` (kw list), `:active`, `:on_change` |
| `navbar(children, opts \\ [])` | top navigation bar |
| `stepper(opts \\ [])` | `:steps` (list), `:active`, `:on_change` |

### Data display

| Helper | Notes |
|---|---|
| `table(rows, opts \\ [])` | `:columns`; pass `:loader` + `:parallel` for async |
| `list(items, opts \\ [])` | `:item` function; `:loader` + `:parallel` for async |
| `key_value(pairs, opts \\ [])` | two-column key-value |
| `stat(label, value, opts \\ [])` | `:trend` (`:up`/`:down`/`:flat`) |
| `timeline(events, opts \\ [])` | list of maps with `:date` / `:event` |
| `avatar(src_or_name, opts \\ [])` | URL or initials |
| `tree(items, opts \\ [])` | recursive tree; `:expanded` keys |

### Feedback / states

| Helper | Notes |
|---|---|
| `spinner(opts \\ [])` | loading spinner |
| `empty(message, opts \\ [])` | empty-state placeholder |
| `error(message, opts \\ [])` | error-state placeholder |
| `progress(fraction, opts \\ [])` | 0.0..1.0; `:label` |
| `alert(message, opts \\ [])` | `:tone`, `:title` |
| `toast(message, opts \\ [])` | transient notification |
| `skeleton(opts \\ [])` | `:width`, `:height` |
| `notification(message, opts \\ [])` | longer-lived notification; `:unread` |

## Colours (optional Pote bridge)

If your app uses `Pote`, every component opts can carry color keys
that get parsed at render time and turned into inline `style`:

```elixir
col([
  text("Primary",  color: "theme:primary"),
  text("Background", bg: "#FFB400"),
  text("Border",   border: "blue"),
  text("Ring",     ring: "theme:error")
])
```

Supported keys: `:color`, `:bg`, `:border`, `:ring`, `:fill`.
Supported formats: hex (`#FF0000`), named CSS (`tomato`),
RGB tuples, HSL / HSV strings (`hsl:0,100,50`), and theme keys
(`theme:primary`).

The bridge is implemented in `Flotilla.Colors` and is loaded
via `Code.ensure_loaded?(Pote)` so it's safe to depend on
or not. See `lib/flotilla/colors.ex` for details.

## Parallel loading (optional Arrea bridge)

`table/2` and `list/2` accept a `:loader` option that produces a
vdom for each row. Set `:parallel: true` to fan out via
`Flotilla.Loader`, which uses `Arrea.run_sync/2` when available
and falls back to sequential execution otherwise:

```elixir
table([1, 2, 3, 4, 5],
  columns: [:n, :square],
  loader: fn n -> %{n: n, square: n * n} end,
  parallel: true
)
```

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

## Documentation

- `README.md` — this file (English)
- `docs/README.es.md` — Spanish version

## License

MIT — see [LICENSE.md](LICENSE.md).
