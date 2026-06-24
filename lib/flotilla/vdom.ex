defmodule Flotilla.VDOM do
  @moduledoc """
  Virtual DOM types and low-level constructors for Flotilla.

  Most users should reach for the helpers in `Flotilla.Components`
  (`col/2`, `row/2`, `button/2`, `table/2`, ...) which return these
  tagged tuples. The raw tuple shapes are exported here so you can
  construct custom nodes if needed.

  ## Tuple shape

  Every node is a tagged tuple `{tag, opts, content}` where:

    * `tag` — atom identifying the node kind (`:col`, `:row`, `:button`,
      `:text`, etc.)
    * `opts` — keyword list of options (`:msg`, `:class`, `:id`, `:on_change`, ...)
    * `content` — children (a list of vdom nodes), a string, or `nil`

  ## Supported tags

    Containers: `:col`, `:row`, `:card`
    Text:       `:text`, `:heading`, `:badge`
    Controls:   `:button`, `:input`, `:select`, `:checkbox`
    Data:       `:table`, `:list`, `:key_value`
    States:     `:spinner`, `:empty`, `:error`
  """

  @type tag ::
          :col
          | :row
          | :card
          | :text
          | :heading
          | :badge
          | :button
          | :input
          | :select
          | :checkbox
          | :table
          | :list
          | :key_value
          | :spinner
          | :empty
          | :error
          | atom()

  @type opts :: keyword()

  @type child :: t() | String.t() | nil

  @type t ::
          {tag(), opts(), child() | [child()]}

  @doc """
  Constructs a VDOM node from a tag, options, and content.

  Prefer the helpers in `Flotilla.Components` for ergonomic construction.
  """
  @spec node(tag(), opts(), child() | [child()]) :: t()
  def node(tag, opts, content) when is_atom(tag) and is_list(opts) do
    {tag, opts, content}
  end

  @doc """
  Returns true if `term` is a VDOM node (a 3-tuple whose first element is
  a known VDOM tag atom).
  """
  @spec vdom?(term()) :: boolean()
  def vdom?({tag, _opts, _content}) when is_atom(tag), do: true
  def vdom?(_), do: false

  @doc """
  Walks a VDOM tree depth-first, calling `fun` on each node. Returns `:ok`.

  Useful for analytics or instrumentation:

      Flotilla.VDOM.walk(vdom, fn {tag, _opts, _} ->
        IO.puts("node: \#{tag}")
      end)
  """
  @spec walk(t(), (t() -> any())) :: :ok
  def walk({_tag, _opts, content} = node, fun) when is_function(fun, 1) do
    _ = fun.(node)
    walk_children(content, fun)
    :ok
  end

  defp walk_children(children, fun) when is_list(children) do
    Enum.each(children, fn child ->
      if vdom?(child), do: walk(child, fun)
    end)
  end

  defp walk_children(_non_list, _fun), do: :ok
end
