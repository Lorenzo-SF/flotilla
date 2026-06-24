defmodule Flotilla.Components do
  @moduledoc """
  Builder helpers for VDOM nodes used by `view/1` functions.

  Each helper constructs a tagged tuple consumed by `Flotilla.Renderer`.
  Every helper accepts an `opts` keyword list (default `[]`) which becomes
  the second element of the tuple and is interpreted by the renderer
  (`:class`, `:id`, `:msg`, `:on_change`, `:columns`, `:placeholder`, ...).

  Color-related opts (`:color`, `:bg`, `:border`, `:ring`, `:fill`)
  are parsed via `Flotilla.Colors` (an optional Pote bridge) — see
  `Flotilla.Colors` for the full list of accepted formats.

  ## Containers

  Layout primitives. All accept a list of children.

      col([row([text("a"), text("b")]), card([text("hi")])])

    * `col(children, opts \\ [])` — flex column
    * `row(children, opts \\ [])` — flex row
    * `card(children, opts \\ [])` — boxed card with padding + border
    * `divider(opts \\ [])` — horizontal/vertical rule
    * `grid(children, opts \\ [])` — CSS grid (`:cols:`, `:gap:`)
    * `stack(children, opts \\ [])` — vertical stack with consistent gap
    * `center(child, opts \\ [])` — centered single child
    * `segment(children, opts \\ [])` — Semantic UI style section
    * `sidebar(children, opts \\ [])` — fixed-width side panel

  ## Text

      text("Hello")
      heading("Dashboard", level: 1)
      badge("beta", tone: :success)
      label("Field name")
      code("foo()", language: :elixir)
      pre("long code block", language: :elixir)
      kbd("Ctrl+C")
      blockquote("Important note", cite: "...")
      link("Click here", to: "/path", msg: :clicked)
      icon(:check, color: "theme:success")

    * `text(content, opts \\ [])`
    * `heading(content, opts \\ [])` — `level:` (1..6) or class
    * `badge(content, opts \\ [])` — `tone:` (`:success`/`:warning`/`:error`/`:info`)
    * `label(content, opts \\ [])` — form label
    * `code(content, opts \\ [])` — inline `<code>` block
    * `pre(content, opts \\ [])` — `<pre>` block
    * `kbd(content, opts \\ [])` — keyboard key
    * `blockquote(content, opts \\ [])` — `cite:` for source
    * `link(label, opts \\ [])` — `:to`, `:msg`
    * `icon(name, opts \\ [])` — Semantic UI / Heroicons name

  ## Forms

  Interactive form controls. All wire to `handle_event` via `:msg` /
  `:on_change` / `:on_submit`.

      form([input(name: "email"), submit("Save")], on_submit: :save)
      field(input([:email]), label: "Email")
      input(placeholder: "Search...", on_change: :query)
      textarea("initial value", on_change: :body)
      select(["red", "green", "blue"], on_change: :color)
      checkbox(checked: true, on_change: :toggle)
      radio_group([{"Yes", :yes}, {"No", :no}], value: :yes, on_change: :answer)
      switch(checked: false, on_change: :toggle)
      slider(min: 0, max: 100, value: 50, on_change: :volume)
      datepicker(value: ~D[2025-01-01], on_change: :pick)
      submit("Send", msg: :submit)

    * `form(children, opts \\ [])` — `:on_submit`, `:method`, `:action`
    * `field(child, opts \\ [])` — `:label`, `:hint`, `:error`
    * `input(opts \\ [])` — `:placeholder`, `:value`, `:on_change`, `:type`
    * `textarea(content, opts \\ [])` — like input, multi-line
    * `select(options, opts \\ [])` — strings or `{label, value}` tuples
    * `checkbox(opts \\ [])` — `:checked`, `:on_change`
    * `radio_group(options, opts \\ [])` — `:value`, `:on_change`
    * `switch(opts \\ [])` — toggle on/off
    * `slider(opts \\ [])` — `:min`, `:max`, `:value`, `:step`, `:on_change`
    * `datepicker(opts \\ [])` — `:value`, `:on_change`
    * `submit(label, opts \\ [])` — submits the enclosing form

  ## Navigation

      menu([link("Home", to: "/"), link("About", to: "/about")])
      breadcrumb([link("Home", to: "/"), text("Docs")])
      pagination(current_page: 2, total_pages: 10, on_change: :goto)
      tabs(active: :overview, tabs: [overview: "Overview", detail: "Detail"])
      navbar([link("Logo", to: "/"), menu([...])])
      stepper(active: 2, steps: ["Cart", "Shipping", "Payment"])

    * `menu(children, opts \\ [])`
    * `breadcrumb(items, opts \\ [])`
    * `pagination(opts \\ [])` — `:current_page`, `:total_pages`, `:on_change`
    * `tabs(opts \\ [])` — `:tabs` (keyword list), `:active`, `:on_change`
    * `navbar(children, opts \\ [])`
    * `stepper(opts \\ [])` — `:steps` (list), `:active`, `:on_change`

  ## Data display

      table(rows, columns: [:id, :name, :status])
      list(items, item: fn item -> row([text(item.name)]) end)
      key_value([{"User", "alice"}, {"Plan", "pro"}])
      stat("Total users", "1,234", trend: :up)
      timeline([{date: "2025-01-01", event: "Created"}, ...])
      avatar("https://...", name: "Lorenzo")
      tree(items, expanded: ["root"])

    * `table(rows, opts \\ [])`
    * `list(items, opts \\ [])`
    * `key_value(pairs, opts \\ [])`
    * `stat(label, value, opts \\ [])` — `:trend` (`:up`/`:down`/`:flat`)
    * `timeline(events, opts \\ [])` — list of maps with `:date`/`:event`
    * `avatar(src_or_name, opts \\ [])`
    * `tree(items, opts \\ [])` — `:expanded` list of keys

  ## Feedback / states

      spinner()
      empty("No items yet")
      error("Something went wrong")
      progress(0.65, label: "Loading 65%")
      alert("Heads up!", tone: :warning)
      toast("Saved!", tone: :success)
      skeleton(width: 200, height: 20)
      notification("You have 3 new messages", unread: true)

    * `spinner(opts \\ [])`
    * `empty(message, opts \\ [])`
    * `error(message, opts \\ [])`
    * `progress(fraction, opts \\ [])` — `0.0..1.0`
    * `alert(message, opts \\ [])` — `tone:` per badge
    * `toast(message, opts \\ [])`
    * `skeleton(opts \\ [])` — `:width`, `:height`
    * `notification(message, opts \\ [])` — `:unread`
  """

  alias Flotilla.VDOM

  # ===========================================================================
  # Containers
  # ===========================================================================

  @doc "Flex column container."
  @spec col([VDOM.t()], keyword()) :: VDOM.t()
  def col(children, opts \\ []) when is_list(children), do: VDOM.node(:col, opts, children)

  @doc "Flex row container."
  @spec row([VDOM.t()], keyword()) :: VDOM.t()
  def row(children, opts \\ []) when is_list(children), do: VDOM.node(:row, opts, children)

  @doc "Bordered card container with default padding."
  @spec card([VDOM.t()], keyword()) :: VDOM.t()
  def card(children, opts \\ []) when is_list(children), do: VDOM.node(:card, opts, children)

  @doc """
  Horizontal (`:horizontal`, default) or vertical (`:vertical`) rule.
  Pass `:label` for a labelled divider (Semantic UI style).
  """
  @spec divider(keyword()) :: VDOM.t()
  def divider(opts \\ []) when is_list(opts), do: VDOM.node(:divider, opts, nil)

  @doc """
  CSS grid. `:cols` defaults to 3. `:gap` defaults to `"gap-2"`.
  """
  @spec grid([VDOM.t()], keyword()) :: VDOM.t()
  def grid(children, opts \\ []) when is_list(children), do: VDOM.node(:grid, opts, children)

  @doc "Vertical stack with consistent gap (Semantic UI style)."
  @spec stack([VDOM.t()], keyword()) :: VDOM.t()
  def stack(children, opts \\ []) when is_list(children), do: VDOM.node(:stack, opts, children)

  @doc "Centred single child wrapper."
  @spec center(VDOM.t(), keyword()) :: VDOM.t()
  def center(child, opts \\ []) when is_tuple(child) or is_binary(child),
    do: VDOM.node(:center, opts, List.wrap(child))

  @doc "Section grouping (Semantic UI segment)."
  @spec segment([VDOM.t()], keyword()) :: VDOM.t()
  def segment(children, opts \\ []) when is_list(children),
    do: VDOM.node(:segment, opts, children)

  @doc "Fixed-width side panel."
  @spec sidebar([VDOM.t()], keyword()) :: VDOM.t()
  def sidebar(children, opts \\ []) when is_list(children),
    do: VDOM.node(:sidebar, opts, children)

  # ===========================================================================
  # Text
  # ===========================================================================

  @doc "Plain text node."
  @spec text(String.t(), keyword()) :: VDOM.t()
  def text(content, opts \\ []) when is_binary(content), do: VDOM.node(:text, opts, content)

  @doc "Heading. Pass `:level` (1..6) or rely on the default `<h2>`."
  @spec heading(String.t(), keyword()) :: VDOM.t()
  def heading(content, opts \\ []) when is_binary(content), do: VDOM.node(:heading, opts, content)

  @doc """
  Pill-style status badge.

  Supported tones: `:success` / `:warning` / `:error` / `:info` / `:neutral`.
  """
  @spec badge(String.t(), keyword()) :: VDOM.t()
  def badge(content, opts \\ []) when is_binary(content), do: VDOM.node(:badge, opts, content)

  @doc "Form label associated with a control."
  @spec label(String.t(), keyword()) :: VDOM.t()
  def label(content, opts \\ []) when is_binary(content), do: VDOM.node(:label, opts, content)

  @doc "Inline `<code>` block. `:language` is informational only."
  @spec code(String.t(), keyword()) :: VDOM.t()
  def code(content, opts \\ []) when is_binary(content), do: VDOM.node(:code, opts, content)

  @doc "Multi-line `<pre>` block. `:language` adds a CSS class hint."
  @spec pre(String.t(), keyword()) :: VDOM.t()
  def pre(content, opts \\ []) when is_binary(content), do: VDOM.node(:pre, opts, content)

  @doc "Keyboard key indicator (e.g. `<kbd>Ctrl+C</kbd>`)."
  @spec kbd(String.t(), keyword()) :: VDOM.t()
  def kbd(content, opts \\ []) when is_binary(content), do: VDOM.node(:kbd, opts, content)

  @doc "Block quote. Pass `:cite` for source URL."
  @spec blockquote(String.t(), keyword()) :: VDOM.t()
  def blockquote(content, opts \\ []) when is_binary(content),
    do: VDOM.node(:blockquote, opts, content)

  @doc """
  Link element. `:to` is the href; pass `:msg` to intercept the click
  with `phx-click` (the `to` is preserved in `data-href` for navigation).
  """
  @spec link(String.t(), keyword()) :: VDOM.t()
  def link(label, opts \\ []) when is_binary(label), do: VDOM.node(:link, opts, label)

  @doc """
  Icon placeholder. `:name` is an atom (e.g. `:check`, `:arrow_right`,
  `:user`) that downstream renders map to font/glyph. `:class` can
  override the default sizing.
  """
  @spec icon(atom() | String.t(), keyword()) :: VDOM.t()
  def icon(name, opts \\ []) when is_atom(name) or is_binary(name),
    do: VDOM.node(:icon, opts, name)

  # ===========================================================================
  # Forms
  # ===========================================================================

  @doc """
  Form wrapper. Pass `:on_submit` to wire `phx-submit`. `:method` and
  `:action` set the corresponding HTML attributes.
  """
  @spec form([VDOM.t()], keyword()) :: VDOM.t()
  def form(children, opts \\ []) when is_list(children), do: VDOM.node(:form, opts, children)

  @doc """
  Form field wrapper bundling a label, control, hint, and error message.

      field(input(name: "email"), label: "Email", hint: "We never share it")
  """
  @spec field(VDOM.t(), keyword()) :: VDOM.t()
  def field(child, opts \\ []) when is_tuple(child), do: VDOM.node(:field, opts, child)

  @doc """
  Button. `:msg` is rendered as a `phx-click` event handler.
  """
  @spec button(String.t(), keyword()) :: VDOM.t()
  def button(label, opts \\ []) when is_binary(label), do: VDOM.node(:button, opts, label)

  @doc """
  Text input. Supports `:placeholder`, `:value`, `:on_change`, `:name`,
  `:id`, `:class`, `:type` (defaults to `"text"`).
  """
  @spec input(keyword()) :: VDOM.t()
  def input(opts \\ []) when is_list(opts), do: VDOM.node(:input, opts, nil)

  @doc "Multi-line text input."
  @spec textarea(String.t(), keyword()) :: VDOM.t()
  def textarea(content, opts \\ []) when is_binary(content),
    do: VDOM.node(:textarea, opts, content)

  @doc """
  Select element. `options` is a list of strings or `{label, value}` tuples.
  Supports `:on_change`, `:value`, `:name`.
  """
  @spec select([String.t() | {String.t(), term()}], keyword()) :: VDOM.t()
  def select(options, opts \\ []) when is_list(options), do: VDOM.node(:select, opts, options)

  @doc "Checkbox. Pass `:checked` (boolean) and `:on_change`."
  @spec checkbox(keyword()) :: VDOM.t()
  def checkbox(opts \\ []) when is_list(opts), do: VDOM.node(:checkbox, opts, nil)

  @doc """
  Radio group. `options` is `[{"Yes", :yes}, {"No", :no}]`. `:value`
  selects the active option.
  """
  @spec radio_group([{String.t(), term()}], keyword()) :: VDOM.t()
  def radio_group(options, opts \\ []) when is_list(options),
    do: VDOM.node(:radio_group, opts, options)

  @doc "Toggle switch (on/off). Pass `:checked` and `:on_change`."
  @spec switch(keyword()) :: VDOM.t()
  def switch(opts \\ []) when is_list(opts), do: VDOM.node(:switch, opts, nil)

  @doc """
  Range slider. `:min` / `:max` (default 0..100), `:value`, `:step`,
  `:on_change`.
  """
  @spec slider(keyword()) :: VDOM.t()
  def slider(opts \\ []) when is_list(opts), do: VDOM.node(:slider, opts, nil)

  @doc """
  Date picker. `:value` is a `Date.t()`; `:on_change` receives a `Date.t()`.
  """
  @spec datepicker(keyword()) :: VDOM.t()
  def datepicker(opts \\ []) when is_list(opts), do: VDOM.node(:datepicker, opts, nil)

  @doc "Form submit button."
  @spec submit(String.t(), keyword()) :: VDOM.t()
  def submit(label, opts \\ []) when is_binary(label), do: VDOM.node(:submit, opts, label)

  # ===========================================================================
  # Navigation
  # ===========================================================================

  @doc "Horizontal or vertical menu of links / buttons."
  @spec menu([VDOM.t()], keyword()) :: VDOM.t()
  def menu(children, opts \\ []) when is_list(children), do: VDOM.node(:menu, opts, children)

  @doc "Breadcrumb trail. Items can be `link/2`, `text/2`, or any VDOM."
  @spec breadcrumb([VDOM.t()], keyword()) :: VDOM.t()
  def breadcrumb(items, opts \\ []) when is_list(items), do: VDOM.node(:breadcrumb, opts, items)

  @doc """
  Pagination control. `:current_page`, `:total_pages`, `:on_change`
  receives the new page number.
  """
  @spec pagination(keyword()) :: VDOM.t()
  def pagination(opts \\ []) when is_list(opts), do: VDOM.node(:pagination, opts, nil)

  @doc """
  Tab strip. `:tabs` is a keyword list (`:overview => "Overview"`),
  `:active` is the key of the current tab, `:on_change` receives the key.
  """
  @spec tabs(keyword()) :: VDOM.t()
  def tabs(opts \\ []) when is_list(opts), do: VDOM.node(:tabs, opts, nil)

  @doc "Top navigation bar."
  @spec navbar([VDOM.t()], keyword()) :: VDOM.t()
  def navbar(children, opts \\ []) when is_list(children), do: VDOM.node(:navbar, opts, children)

  @doc """
  Stepper / wizard steps. `:steps` is a list of strings, `:active` is
  the index of the current step (0-based), `:on_change` receives it.
  """
  @spec stepper(keyword()) :: VDOM.t()
  def stepper(opts \\ []) when is_list(opts), do: VDOM.node(:stepper, opts, nil)

  # ===========================================================================
  # Data display
  # ===========================================================================

  @doc """
  Table from a list of maps. `opts[:columns]` is required and is the list
  of columns to render (atoms become keys on each row, strings are used
  verbatim as headers).

  ## Async loading

  Pass `:loader` as a function `(row -> data)` that runs in parallel
  via `Flotilla.Loader` (which uses `Arrea.run_sync/2` when available).
  When `loader:` is set, the table expects a list of `{:row, raw}`
  tuples; the renderer resolves them concurrently.

      table([{:row, fn -> fetch_user(id) end}], columns: [:name])
  """
  @spec table([map() | list() | tuple()], keyword()) :: VDOM.t()
  def table(rows, opts \\ []) when is_list(rows), do: VDOM.node(:table, opts, rows)

  @doc """
  Vertical list. `opts[:item]` is a function `(element -> vdom)` applied to
  each element of `items`. Use `:loader:` for parallel resolution (see `table/2`).
  """
  @spec list([any()], keyword()) :: VDOM.t()
  def list(items, opts \\ []) when is_list(items), do: VDOM.node(:list, opts, items)

  @doc """
  Key-value pairs rendered as a two-column table.

      key_value([{"User", "alice"}, {"Plan", "pro"}])
  """
  @spec key_value([{String.t(), term()}], keyword()) :: VDOM.t()
  def key_value(pairs, opts \\ []) when is_list(pairs), do: VDOM.node(:key_value, opts, pairs)

  @doc """
  Stat tile — large label + value pair with optional trend arrow.

      stat("Total users", "1,234", trend: :up)
  """
  @spec stat(String.t(), term(), keyword()) :: VDOM.t()
  def stat(label, value, opts \\ []) when is_binary(label),
    do: VDOM.node(:stat, opts, %{label: label, value: to_string(value)})

  @doc """
  Timeline of events. `events` is a list of maps with `:date` (or `:when`)
  and `:event` (or `:what`) keys.
  """
  @spec timeline([map()], keyword()) :: VDOM.t()
  def timeline(events, opts \\ []) when is_list(events), do: VDOM.node(:timeline, opts, events)

  @doc """
  Avatar — image URL, initials, or icon. `:name` shows a fallback
  initial when no URL is provided.
  """
  @spec avatar(String.t() | nil, keyword()) :: VDOM.t()
  def avatar(src, opts \\ []) when is_binary(src) or is_nil(src),
    do: VDOM.node(:avatar, opts, src)

  @doc """
  Tree view. `:items` is a recursive structure:

      [{key: "a", label: "A", children: [...]}]

  `:expanded` is a list of keys that should be open.
  """
  @spec tree([map()], keyword()) :: VDOM.t()
  def tree(items, opts \\ []) when is_list(items), do: VDOM.node(:tree, opts, items)

  # ===========================================================================
  # Feedback / states
  # ===========================================================================

  @doc "Loading spinner."
  @spec spinner(keyword()) :: VDOM.t()
  def spinner(opts \\ []) when is_list(opts), do: VDOM.node(:spinner, opts, nil)

  @doc "Empty-state placeholder."
  @spec empty(String.t(), keyword()) :: VDOM.t()
  def empty(message, opts \\ []) when is_binary(message), do: VDOM.node(:empty, opts, message)

  @doc "Error-state placeholder."
  @spec error(String.t(), keyword()) :: VDOM.t()
  def error(message, opts \\ []) when is_binary(message), do: VDOM.node(:error, opts, message)

  @doc """
  Progress bar. `fraction` is `0.0..1.0`. Pass `:label` for a
  descriptive label and `:value` to override the displayed percentage.
  """
  @spec progress(float(), keyword()) :: VDOM.t()
  def progress(fraction, opts \\ []) when is_number(fraction),
    do: VDOM.node(:progress, opts, fraction)

  @doc """
  Inline alert / callout. `:tone:` (`:info` / `:success` / `:warning` /
  `:error`) and `:title:` for the bold heading.
  """
  @spec alert(String.t(), keyword()) :: VDOM.t()
  def alert(message, opts \\ []) when is_binary(message), do: VDOM.node(:alert, opts, message)

  @doc "Toast notification — short, transient."
  @spec toast(String.t(), keyword()) :: VDOM.t()
  def toast(message, opts \\ []) when is_binary(message), do: VDOM.node(:toast, opts, message)

  @doc """
  Placeholder skeleton for loading states. `:width` / `:height`
  accept CSS values (`"200px"`, `"100%"`, etc.).
  """
  @spec skeleton(keyword()) :: VDOM.t()
  def skeleton(opts \\ []) when is_list(opts), do: VDOM.node(:skeleton, opts, nil)

  @doc "Notification card — longer-lived than `toast`."
  @spec notification(String.t(), keyword()) :: VDOM.t()
  def notification(message, opts \\ []) when is_binary(message),
    do: VDOM.node(:notification, opts, message)
end
