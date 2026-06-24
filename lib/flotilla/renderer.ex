defmodule Flotilla.Renderer do
  @moduledoc """
  Converts a VDOM tree into a `Phoenix.LiveView.LiveStruct` (HEEx) for use
  inside `Phoenix.LiveView.render/1`.

  You typically don't call this directly — `Flotilla.View`'s macro wires
  it up. Direct calls are useful for tests:

      iex> vdom = Flotilla.Components.text("hi")
      iex> %{struct: Phoenix.LiveView.LiveStruct} = Flotilla.Renderer.to_heex(vdom)
  """

  alias Flotilla.VDOM

  # Default Tailwind-style classes applied when `class:` is not given.
  @default_class_by_tag %{
    col: "flex flex-col gap-2",
    row: "flex flex-row gap-2 items-center",
    card: "border border-gray-300 rounded p-4 bg-white shadow-sm",
    text: "",
    heading: "text-2xl font-semibold",
    badge: "px-2 py-0.5 rounded-full text-xs font-medium",
    button:
      "px-3 py-1.5 rounded bg-blue-500 text-white hover:bg-blue-600 transition cursor-pointer",
    input: "border border-gray-300 rounded px-2 py-1",
    select: "border border-gray-300 rounded px-2 py-1 bg-white",
    checkbox: "h-4 w-4",
    table: "w-full text-left border-collapse",
    list: "flex flex-col gap-1",
    key_value: "w-full",
    spinner: "animate-spin h-4 w-4 border-2 border-blue-500 border-t-transparent rounded-full",
    empty: "text-gray-500 italic text-center py-8",
    error: "text-red-600 font-medium text-center py-8"
  }

  @badge_tone_class %{
    success: "bg-green-100 text-green-800",
    warning: "bg-yellow-100 text-yellow-800",
    error: "bg-red-100 text-red-800",
    info: "bg-blue-100 text-blue-800",
    neutral: "bg-gray-100 text-gray-800"
  }

  @doc """
  Render a VDOM tree as a HEEx template.

  Returns a `Phoenix.LiveView.LiveStruct` (the result of
  `Phoenix.LiveView.TagEngine.component/3`). The user's `render/1`
  callback is expected to return this directly.
  """
  @spec to_heex(VDOM.t()) :: Phoenix.LiveView.LiveStruct.t()
  def to_heex(vdom) do
    env = __ENV__

    Phoenix.LiveView.TagEngine.component(
      &render_node/1,
      %{node: vdom},
      {env.module, env.function, env.file, env.line}
    )
  end

  # ---------------------------------------------------------------------------
  # Renderer — one clause per VDOM tag
  # ---------------------------------------------------------------------------

  # Containers
  defp render_node(%{node: {:col, opts, children}}) do
    class = class_with_default(opts, :col)
    html(:div, [class: class], Enum.map(children_to_list(children), &render_child/1))
  end

  defp render_node(%{node: {:row, opts, children}}) do
    class = class_with_default(opts, :row)
    html(:div, [class: class], Enum.map(children_to_list(children), &render_child/1))
  end

  defp render_node(%{node: {:card, opts, children}}) do
    class = class_with_default(opts, :card)
    html(:div, [class: class], Enum.map(children_to_list(children), &render_child/1))
  end

  # Text
  defp render_node(%{node: {:text, opts, content}}) do
    class = class_with_default(opts, :text)
    attrs = build_attrs(class, opts, [:class, :id])
    {:safe, ["<span", attrs, ">", escape_html(content), "</span>"]}
  end

  defp render_node(%{node: {:heading, opts, content}}) do
    class = class_with_default(opts, :heading)
    level = Keyword.get(opts, :level, 2) |> clamp_level()
    tag = "h#{level}"
    attrs = build_attrs(class, opts, [:class, :id])
    {:safe, ["<", tag, attrs, ">", escape_html(content), "</", tag, ">"]}
  end

  defp render_node(%{node: {:badge, opts, content}}) do
    base = class_with_default(opts, :badge)
    tone = Keyword.get(opts, :tone, :neutral)
    tone_class = Map.get(@badge_tone_class, tone, @badge_tone_class.neutral)
    full_class = "#{base} #{tone_class}" |> String.trim()
    {:safe, ["<span class=\"", full_class, "\">", escape_html(content), "</span>"]}
  end

  # Controls
  defp render_node(%{node: {:button, opts, label}}) do
    class = class_with_default(opts, :button)
    attrs = [class: class]

    attrs =
      case Keyword.get(opts, :msg) do
        nil -> attrs
        msg -> [{:"phx-click", to_string(msg)} | attrs]
      end

    attrs = build_attrs(attrs, opts, [:class, :id, :type, :disabled])
    {:safe, ["<button", attrs, ">", escape_html(label), "</button>"]}
  end

  defp render_node(%{node: {:input, opts, nil}}) do
    class = class_with_default(opts, :input)
    base = [class: class, type: Keyword.get(opts, :type, "text")]
    attrs =
      case Keyword.get(opts, :on_change) do
        nil -> base
        ev -> [{:"phx-change", to_string(ev)} | base]
      end

    attrs =
      case Keyword.get(opts, :value) do
        nil -> attrs
        v -> [{:value, to_string(v)} | attrs]
      end

    attrs = build_attrs(attrs, opts, [:class, :id, :type, :placeholder, :name, :value])
    {:safe, ["<input", attrs, "/>"]}
  end

  defp render_node(%{node: {:select, opts, options}}) do
    class = class_with_default(opts, :select)
    base = [class: class]

    attrs =
      case Keyword.get(opts, :on_change) do
        nil -> base
        ev -> [{:"phx-change", to_string(ev)} | base]
      end

    attrs = build_attrs(attrs, opts, [:class, :id, :name])
    selected = Keyword.get(opts, :value)

    rendered_opts =
      options
      |> Enum.map(fn
        {label, value} ->
          sel = if value == selected, do: " selected", else: ""
          {:safe, ["<option value=\"", escape_attr(to_string(value)), "\"", sel, ">", escape_html(label), "</option>"]}

        value when is_binary(value) ->
          sel = if value == selected, do: " selected", else: ""
          {:safe, ["<option value=\"", escape_attr(value), "\"", sel, ">", escape_html(value), "</option>"]}
      end)

    {:safe, ["<select", attrs, ">", rendered_opts, "</select>"]}
  end

  defp render_node(%{node: {:checkbox, opts, nil}}) do
    class = class_with_default(opts, :checkbox)
    base = [class: class, type: "checkbox"]

    base =
      if Keyword.get(opts, :checked, false),
        do: [{:checked, true} | base],
        else: base

    attrs =
      case Keyword.get(opts, :on_change) do
        nil -> base
        ev -> [{:"phx-change", to_string(ev)} | base]
      end

    attrs = build_attrs(attrs, opts, [:class, :id, :type, :name, :value])
    {:safe, ["<input", attrs, "/>"]}
  end

  # Data
  defp render_node(%{node: {:table, opts, rows}}) do
    class = class_with_default(opts, :table)
    columns = Keyword.get(opts, :columns, [])
    headers = render_table_headers(columns)
    body = render_table_rows(rows, columns)
    {:safe,
     [
       "<table class=\"",
       class,
       "\"><thead>",
       headers,
       "</thead><tbody>",
       body,
       "</tbody></table>"
     ]}
  end

  defp render_node(%{node: {:list, opts, items}}) do
    class = class_with_default(opts, :list)
    item_fun = Keyword.get(opts, :item)

    rendered =
      Enum.map(items, fn item ->
        rendered_item(item_fun, item)
      end)

    {:safe, ["<ul class=\"", class, "\">", rendered, "</ul>"]}
  end

  defp render_node(%{node: {:key_value, opts, pairs}}) do
    class = class_with_default(opts, :key_value)
    rows =
      Enum.map(pairs, fn {k, v} ->
        {:safe,
         [
           "<tr><th class=\"text-left pr-4 align-top\">",
           escape_html(to_string(k)),
           "</th><td>",
           escape_html(to_string(v)),
           "</td></tr>"
         ]}
      end)

    {:safe, ["<table class=\"", class, "\"><tbody>", rows, "</tbody></table>"]}
  end

  # States
  defp render_node(%{node: {:spinner, opts, nil}}) do
    class = class_with_default(opts, :spinner)
    {:safe, ["<div class=\"", class, "\" aria-label=\"loading\"></div>"]}
  end

  defp render_node(%{node: {:empty, opts, message}}) do
    class = class_with_default(opts, :empty)
    {:safe, ["<div class=\"", class, "\">", escape_html(message), "</div>"]}
  end

  defp render_node(%{node: {:error, opts, message}}) do
    class = class_with_default(opts, :error)
    {:safe, ["<div class=\"", class, "\">", escape_html(message), "</div>"]}
  end

  # Unknown tag — best-effort fallback. Renders as a div with the tag's atom
  # in data-tag so the user can debug without losing content.
  defp render_node(%{node: {tag, opts, content}}) when is_atom(tag) do
    children = children_to_list(content) |> Enum.map(&render_child/1)
    class = Keyword.get(opts, :class, "")
    {:safe,
     [
       "<div class=\"",
       class,
       "\" data-tag=\"",
       Atom.to_string(tag),
       "\">",
       children,
       "</div>"
     ]}
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp render_child(child) when is_binary(child), do: escape_html(child)
  defp render_child({_tag, _opts, _content} = vdom), do: render_node(%{node: vdom})
  defp render_child(nil), do: ""

  defp children_to_list(children) when is_list(children), do: children
  defp children_to_list(nil), do: []
  defp children_to_list(child), do: [child]

  defp class_with_default(opts, tag) do
    case Keyword.get(opts, :class) do
      nil -> Map.get(@default_class_by_tag, tag, "")
      custom -> custom
    end
  end

  # Builds an attribute list, keeping only the keys in `allowed` from opts
  # and merging with the defaults.
  defp build_attrs(default_attrs, opts, allowed) do
    attrs_from_opts =
      Enum.reduce(opts, default_attrs, fn {k, v}, acc ->
        if k in allowed do
          [{k, v} | acc]
        else
          acc
        end
      end)

    case attrs_from_opts do
      [] -> []
      _ -> attrs_to_safe_string(attrs_from_opts)
    end
  end

  # Build " key=\"value\" key2=\"value2\"" from a keyword list.
  # We render manually because each Phoenix.LiveView callback expects an
  # iodata; for these tests we keep things simple and use {:safe, ...}.
  defp attrs_to_safe_string(attrs) do
    pieces =
      Enum.map(attrs, fn
        {k, true} -> " #{k}=\"true\""
        {k, false} -> " #{k}=\"false\""
        {k, nil} -> ""
        {k, v} -> " #{k}=\"#{escape_attr(to_string(v))}\""
      end)

    {:safe, Enum.join(pieces, "")}
  end

  defp html(tag_atom, attrs, children) do
    {:safe, ["<", Atom.to_string(tag_atom), attrs_to_safe_string(attrs), ">", children, "</", Atom.to_string(tag_atom), ">"]}
  end

  defp escape_html(str) when is_binary(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp escape_html(other), do: escape_html(to_string(other))

  defp escape_attr(str) when is_binary(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
  end

  defp escape_attr(other), do: escape_attr(to_string(other))

  defp clamp_level(n) when is_integer(n) and n >= 1 and n <= 6, do: n
  defp clamp_level(_), do: 2

  defp render_table_headers(columns) do
    Enum.map(columns, fn
      col when is_atom(col) ->
        {:safe, ["<th>", escape_html(Atom.to_string(col)), "</th>"]}

      col when is_binary(col) ->
        {:safe, ["<th>", escape_html(col), "</th>"]}
    end)
  end

  defp render_table_rows(rows, columns) do
    Enum.map(rows, fn row ->
      cells =
        Enum.map(columns, fn col ->
          value =
            cond do
              is_map(row) and is_atom(col) -> Map.get(row, col, "")
              is_map(row) and is_binary(col) -> Map.get(row, col, "")
              is_list(row) and is_integer(col) -> Enum.at(row, col, "") |> to_string()
              true -> ""
            end

          {:safe, ["<td>", escape_html(to_string(value)), "</td>"]}
        end)

      {:safe, ["<tr>", cells, "</tr>"]}
    end)
  end

  defp rendered_item(nil, item), do: escape_html(to_string(item))
  defp rendered_item(fun, item) when is_function(fun, 1), do: render_node(%{node: fun.(item)})
end
