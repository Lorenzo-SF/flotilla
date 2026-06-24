defmodule Flotilla.Components do
  @moduledoc """
  Builder helpers for VDOM nodes used by `view/1` functions.

  Each helper constructs a tagged tuple consumed by `Flotilla.Renderer`.
  Every helper accepts an `opts` keyword list (default `[]`) which becomes
  the second element of the tuple and is interpreted by the renderer
  (`:class`, `:id`, `:msg`, `:on_change`, `:columns`, `:placeholder`, ...).

  ## Containers

  Layout primitives. All accept a list of children.

      col([row([text("a"), text("b")]), card([text("hi")])])

    * `col(children, opts \\ [])` — flex column
    * `row(children, opts \\ [])` — flex row
    * `card(children, opts \\ [])` — boxed card with padding + border

  ## Text

      text("Hello")
      heading("Dashboard", level: 1)
      badge("beta", tone: :success)

    * `text(content, opts \\ [])`
    * `heading(content, opts \\ [])` — `level:` (1..6) or class
    * `badge(content, opts \\ [])` — `tone:` (`:success`/`:warning`/`:error`/`:info`)

  ## Controls

  Interactive elements.

      button("Save", msg: :save)
      input(placeholder: "Search...", on_change: :query)
      select(["red", "green", "blue"], on_change: :color)
      checkbox(checked: true, on_change: :toggle)

    * `button(label, opts \\ [])` — `:msg` (event), `:class`
    * `input(opts \\ [])` — `:placeholder`, `:value`, `:on_change`
    * `select(options, opts \\ [])` — list of strings or `{label, value}` tuples
    * `checkbox(opts \\ [])` — `:checked`, `:on_change`

  ## Data

      table(rows, columns: [:id, :name, :status])
      list(items, item: fn item -> row([text(item.name)]) end)
      key_value([{"User", "alice"}, {"Plan", "pro"}])

    * `table(rows, opts \\ [])` — `:columns` (list of atoms or strings)
    * `list(items, opts \\ [])` — `:item` (function `(elem -> vdom)`)
    * `key_value(pairs, opts \\ [])`

  ## States

      spinner()
      empty("No items yet")
      error("Something went wrong")

    * `spinner(opts \\ [])`
    * `empty(message, opts \\ [])`
    * `error(message, opts \\ [])`
  """

  alias Flotilla.VDOM

  # ---------------------------------------------------------------------------
  # Containers
  # ---------------------------------------------------------------------------

  @doc "Flex column container."
  @spec col([VDOM.t()], keyword()) :: VDOM.t()
  def col(children, opts \\ []) when is_list(children), do: VDOM.node(:col, opts, children)

  @doc "Flex row container."
  @spec row([VDOM.t()], keyword()) :: VDOM.t()
  def row(children, opts \\ []) when is_list(children), do: VDOM.node(:row, opts, children)

  @doc "Bordered card container with default padding."
  @spec card([VDOM.t()], keyword()) :: VDOM.t()
  def card(children, opts \\ []) when is_list(children), do: VDOM.node(:card, opts, children)

  # ---------------------------------------------------------------------------
  # Text
  # ---------------------------------------------------------------------------

  @doc "Plain text node."
  @spec text(String.t(), keyword()) :: VDOM.t()
  def text(content, opts \\ []) when is_binary(content), do: VDOM.node(:text, opts, content)

  @doc "Heading. Pass `:level` (1..6) or rely on the default `<h2>`."
  @spec heading(String.t(), keyword()) :: VDOM.t()
  def heading(content, opts \\ []) when is_binary(content), do: VDOM.node(:heading, opts, content)

  @doc """
  Pill-style status badge.

  Supported tones:
    * `:success` (green)
    * `:warning` (yellow)
    * `:error` (red)
    * `:info` (blue)
    * `:neutral` (grey — default)
  """
  @spec badge(String.t(), keyword()) :: VDOM.t()
  def badge(content, opts \\ []) when is_binary(content), do: VDOM.node(:badge, opts, content)

  # ---------------------------------------------------------------------------
  # Controls
  # ---------------------------------------------------------------------------

  @doc """
  Click button. Pass `:msg` to wire `phx-click` to a `handle_event` call.
  """
  @spec button(String.t(), keyword()) :: VDOM.t()
  def button(label, opts \\ []) when is_binary(label), do: VDOM.node(:button, opts, label)

  @doc """
  Text input. Supports `:placeholder`, `:value`, `:on_change`, `:name`,
  `:id`, `:class`.
  """
  @spec input(keyword()) :: VDOM.t()
  def input(opts \\ []) when is_list(opts), do: VDOM.node(:input, opts, nil)

  @doc """
  Select element. `options` is a list of strings or `{label, value}` tuples.
  Supports `:on_change`, `:value`, `:name`.
  """
  @spec select([String.t() | {String.t(), term()}], keyword()) :: VDOM.t()
  def select(options, opts \\ []) when is_list(options), do: VDOM.node(:select, opts, options)

  @doc """
  Checkbox. Pass `:checked` (boolean) and `:on_change`.
  """
  @spec checkbox(keyword()) :: VDOM.t()
  def checkbox(opts \\ []) when is_list(opts), do: VDOM.node(:checkbox, opts, nil)

  # ---------------------------------------------------------------------------
  # Data
  # ---------------------------------------------------------------------------

  @doc """
  Table from a list of maps. `opts[:columns]` is required and is the list
  of columns to render (atoms become keys on each row, strings are used
  verbatim as headers).
  """
  @spec table([map() | list()], keyword()) :: VDOM.t()
  def table(rows, opts \\ []) when is_list(rows), do: VDOM.node(:table, opts, rows)

  @doc """
  Vertical list. `opts[:item]` is a function `(element -> vdom)` applied to
  each element of `items`.
  """
  @spec list([any()], keyword()) :: VDOM.t()
  def list(items, opts \\ []) when is_list(items), do: VDOM.node(:list, opts, items)

  @doc """
  Key-value pairs rendered as a two-column table.

      key_value([{"User", "alice"}, {"Plan", "pro"}])
  """
  @spec key_value([{String.t(), term()}], keyword()) :: VDOM.t()
  def key_value(pairs, opts \\ []) when is_list(pairs), do: VDOM.node(:key_value, opts, pairs)

  # ---------------------------------------------------------------------------
  # States
  # ---------------------------------------------------------------------------

  @doc "Loading spinner."
  @spec spinner(keyword()) :: VDOM.t()
  def spinner(opts \\ []) when is_list(opts), do: VDOM.node(:spinner, opts, nil)

  @doc "Empty-state placeholder."
  @spec empty(String.t(), keyword()) :: VDOM.t()
  def empty(message, opts \\ []) when is_binary(message), do: VDOM.node(:empty, opts, message)

  @doc "Error-state placeholder."
  @spec error(String.t(), keyword()) :: VDOM.t()
  def error(message, opts \\ []) when is_binary(message), do: VDOM.node(:error, opts, message)
end
