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
  alias Phoenix.LiveView.LiveStruct
  alias Phoenix.LiveView.TagEngine

  # Default Tailwind-style classes applied when `class:` is not given.
  @default_class_by_tag %{
    col: "flex flex-col gap-2",
    row: "flex flex-row gap-2 items-center",
    card: "border border-gray-300 rounded p-4 bg-white shadow-sm",
    divider: "border-t border-gray-200 my-2",
    grid: "grid gap-2",
    stack: "flex flex-col gap-4",
    center: "flex items-center justify-center",
    segment: "p-4 border border-gray-200 rounded",
    sidebar: "w-64 p-4 border-r border-gray-200 bg-gray-50",
    text: "",
    heading: "text-2xl font-semibold",
    badge: "px-2 py-0.5 rounded-full text-xs font-medium",
    label: "block text-sm font-medium text-gray-700 mb-1",
    code: "px-1 py-0.5 bg-gray-100 rounded text-sm font-mono",
    pre: "block p-3 bg-gray-50 rounded font-mono text-sm whitespace-pre overflow-x-auto",
    kbd: "px-1.5 py-0.5 border border-gray-300 rounded bg-gray-50 text-xs font-mono",
    blockquote: "border-l-4 border-gray-300 pl-4 italic text-gray-600",
    link: "text-blue-600 hover:underline cursor-pointer",
    icon: "inline-block w-4 h-4 align-middle",
    form: "flex flex-col gap-3",
    field: "flex flex-col gap-1",
    input: "border border-gray-300 rounded px-2 py-1",
    textarea: "border border-gray-300 rounded px-2 py-1 min-h-[80px]",
    select: "border border-gray-300 rounded px-2 py-1 bg-white",
    checkbox: "h-4 w-4",
    radio_group: "flex flex-col gap-1",
    switch: "inline-block w-10 h-5 rounded-full bg-gray-300 cursor-pointer relative",
    slider: "w-full",
    datepicker: "border border-gray-300 rounded px-2 py-1",
    submit:
      "px-3 py-1.5 rounded bg-blue-500 text-white hover:bg-blue-600 transition cursor-pointer",
    menu: "flex gap-2 items-center",
    breadcrumb: "flex gap-1 text-sm text-gray-600",
    pagination: "flex gap-1 items-center",
    tabs: "flex gap-1 border-b border-gray-200",
    navbar: "flex items-center justify-between px-4 py-2 border-b border-gray-200 bg-white",
    stepper: "flex items-center gap-2",
    table: "w-full text-left border-collapse",
    list: "flex flex-col gap-1",
    key_value: "w-full",
    stat: "p-4 border border-gray-200 rounded",
    timeline: "flex flex-col gap-3 border-l-2 border-gray-200 pl-4",
    avatar: "w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center overflow-hidden",
    tree: "flex flex-col gap-1",
    spinner: "animate-spin h-4 w-4 border-2 border-blue-500 border-t-transparent rounded-full",
    empty: "text-gray-500 italic text-center py-8",
    error: "text-red-600 font-medium text-center py-8",
    progress: "w-full h-2 bg-gray-200 rounded overflow-hidden",
    alert: "p-3 rounded border",
    toast: "p-3 rounded shadow bg-white border",
    skeleton: "bg-gray-200 rounded animate-pulse",
    notification: "p-3 rounded border border-gray-200 bg-white"
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
  @spec to_heex(VDOM.t()) :: LiveStruct.t()
  def to_heex(vdom) do
    env = __ENV__

    TagEngine.component(
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

          {:safe,
           [
             "<option value=\"",
             escape_attr(to_string(value)),
             "\"",
             sel,
             ">",
             escape_html(label),
             "</option>"
           ]}

        value when is_binary(value) ->
          sel = if value == selected, do: " selected", else: ""

          {:safe,
           [
             "<option value=\"",
             escape_attr(value),
             "\"",
             sel,
             ">",
             escape_html(value),
             "</option>"
           ]}
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

  # ---------------------------------------------------------------------------
  # New components — containers
  # ---------------------------------------------------------------------------

  defp render_node(%{node: {:divider, opts, nil}}) do
    class = class_with_default(opts, :divider)
    orientation = Keyword.get(opts, :orientation, :horizontal)
    label = Keyword.get(opts, :label)

    cond do
      label && is_binary(label) ->
        {:safe,
         [
           "<div class=\"flex items-center gap-2 my-2\"><div class=\"flex-1 border-t border-gray-200\"></div><span class=\"text-xs text-gray-500\">",
           escape_html(label),
           "</span><div class=\"flex-1 border-t border-gray-200\"></div></div>"
         ]}

      orientation == :vertical ->
        {:safe, ["<div class=\"inline-block w-px h-full bg-gray-200 mx-2\"></div>"]}

      true ->
        {:safe, ["<hr class=\"", class, "\">"]}
    end
  end

  defp render_node(%{node: {:grid, opts, children}}) do
    cols = Keyword.get(opts, :cols, 3)
    gap = Keyword.get(opts, :gap, "gap-2")
    base = class_with_default(opts, :grid)
    full = "#{base} grid-cols-#{cols} #{gap}" |> String.trim()

    {:safe,
     [
       "<div class=\"",
       full,
       "\">",
       Enum.map(children_to_list(children), &render_child/1),
       "</div>"
     ]}
  end

  defp render_node(%{node: {:stack, opts, children}}) do
    class = class_with_default(opts, :stack)
    html(:div, [class: class], Enum.map(children_to_list(children), &render_child/1))
  end

  defp render_node(%{node: {:center, opts, children}}) do
    class = class_with_default(opts, :center)
    html(:div, [class: class], Enum.map(children_to_list(children), &render_child/1))
  end

  defp render_node(%{node: {:segment, opts, children}}) do
    class = class_with_default(opts, :segment)
    html(:div, [class: class], Enum.map(children_to_list(children), &render_child/1))
  end

  defp render_node(%{node: {:sidebar, opts, children}}) do
    class = class_with_default(opts, :sidebar)
    html(:aside, [class: class], Enum.map(children_to_list(children), &render_child/1))
  end

  # ---------------------------------------------------------------------------
  # New components — text
  # ---------------------------------------------------------------------------

  defp render_node(%{node: {:label, opts, content}}) do
    class = class_with_default(opts, :label)
    attrs = build_attrs(class, opts, [:class, :id, :for])
    {:safe, ["<label", attrs, ">", escape_html(content), "</label>"]}
  end

  defp render_node(%{node: {:code, opts, content}}) do
    class = class_with_default(opts, :code)
    attrs = build_attrs(class, opts, [:class, :id])
    {:safe, ["<code", attrs, ">", escape_html(content), "</code>"]}
  end

  defp render_node(%{node: {:pre, opts, content}}) do
    class = class_with_default(opts, :pre)
    attrs = build_attrs(class, opts, [:class, :id])
    {:safe, ["<pre", attrs, ">", escape_html(content), "</pre>"]}
  end

  defp render_node(%{node: {:kbd, opts, content}}) do
    class = class_with_default(opts, :kbd)
    attrs = build_attrs(class, opts, [:class, :id])
    {:safe, ["<kbd", attrs, ">", escape_html(content), "</kbd>"]}
  end

  defp render_node(%{node: {:blockquote, opts, content}}) do
    class = class_with_default(opts, :blockquote)
    cite = Keyword.get(opts, :cite)
    base = build_attrs(class, opts, [:class, :id])

    attrs =
      if cite, do: [{:cite, cite} | base], else: base

    {:safe, ["<blockquote", attrs, ">", escape_html(content), "</blockquote>"]}
  end

  defp render_node(%{node: {:link, opts, label}}) do
    class = class_with_default(opts, :link)
    to = Keyword.get(opts, :to)
    msg = Keyword.get(opts, :msg)
    base = build_attrs(class, opts, [:class, :id, :target, :rel])

    attrs =
      cond do
        msg -> [{:"phx-click", to_string(msg)} | base]
        to -> [{:href, to} | base]
        true -> base
      end

    attrs =
      if to, do: [{:"data-href", to} | attrs], else: attrs

    {:safe, ["<a", attrs, ">", escape_html(label), "</a>"]}
  end

  defp render_node(%{node: {:icon, opts, name}}) do
    class = class_with_default(opts, :icon)
    name_str = name |> to_string()

    {:safe,
     [
       "<i class=\"",
       class,
       "\" data-icon=\"",
       escape_attr(name_str),
       "\" aria-hidden=\"true\"></i>"
     ]}
  end

  # ---------------------------------------------------------------------------
  # New components — forms
  # ---------------------------------------------------------------------------

  defp render_node(%{node: {:form, opts, children}}) do
    class = class_with_default(opts, :form)
    method = Keyword.get(opts, :method, "post")
    action = Keyword.get(opts, :action, "")
    base = build_attrs(class, opts, [:class, :id])
    attrs = [{:method, method}, {:action, action} | base]

    attrs =
      case Keyword.get(opts, :on_submit) do
        nil -> attrs
        ev -> [{:"phx-submit", to_string(ev)} | attrs]
      end

    {:safe,
     ["<form", attrs, ">", Enum.map(children_to_list(children), &render_child/1), "</form>"]}
  end

  defp render_node(%{node: {:field, opts, child}}) do
    class = class_with_default(opts, :field)
    label_text = Keyword.get(opts, :label)
    hint = Keyword.get(opts, :hint)
    error = Keyword.get(opts, :error)

    label_node =
      if label_text,
        do:
          {:safe,
           [
             "<label class=\"block text-sm font-medium mb-1\">",
             escape_html(to_string(label_text)),
             "</label>"
           ]},
        else: ""

    hint_node =
      if hint,
        do:
          {:safe,
           ["<p class=\"text-xs text-gray-500 mt-1\">", escape_html(to_string(hint)), "</p>"]},
        else: ""

    error_node =
      if error,
        do:
          {:safe,
           ["<p class=\"text-xs text-red-600 mt-1\">", escape_html(to_string(error)), "</p>"]},
        else: ""

    {:safe,
     [
       "<div class=\"",
       class,
       "\">",
       label_node,
       render_node(%{node: child}),
       hint_node,
       error_node,
       "</div>"
     ]}
  end

  defp render_node(%{node: {:textarea, opts, content}}) do
    class = class_with_default(opts, :textarea)
    base = [class: class]

    attrs =
      case Keyword.get(opts, :on_change) do
        nil -> base
        ev -> [{:"phx-change", to_string(ev)} | base]
      end

    attrs = build_attrs(attrs, opts, [:class, :id, :name, :placeholder, :rows, :cols])
    {:safe, ["<textarea", attrs, ">", escape_html(content), "</textarea>"]}
  end

  defp render_node(%{node: {:radio_group, opts, options}}) do
    class = class_with_default(opts, :radio_group)
    selected = Keyword.get(opts, :value)
    name = Keyword.get(opts, :name, "radio")
    on_change = Keyword.get(opts, :on_change)

    rendered =
      options
      |> Enum.map(fn {label, value} ->
        checked = if value == selected, do: " checked", else: ""
        ev_attr = if on_change, do: ~s( phx-change="#{on_change}"), else: ""

        {:safe,
         [
           "<label class=\"flex items-center gap-2\"><input type=\"radio\" name=\"",
           escape_attr(name),
           "\" value=\"",
           escape_attr(to_string(value)),
           "\"",
           checked,
           ev_attr,
           " class=\"h-4 w-4\"><span>",
           escape_html(label),
           "</span></label>"
         ]}
      end)

    {:safe, ["<div class=\"", class, "\">", rendered, "</div>"]}
  end

  defp render_node(%{node: {:switch, opts, nil}}) do
    class = class_with_default(opts, :switch)
    checked = Keyword.get(opts, :checked, false)
    bg = if checked, do: " bg-blue-500", else: ""

    ev_attr =
      case Keyword.get(opts, :on_change) do
        nil -> ""
        ev -> ~s( phx-change="#{ev}")
      end

    {:safe,
     [
       "<span class=\"",
       class,
       bg,
       "\" role=\"switch\" aria-checked=\"",
       to_string(checked),
       "\"",
       ev_attr,
       "><span class=\"absolute top-0.5 ",
       if(checked, do: "right-0.5", else: "left-0.5"),
       " w-4 h-4 bg-white rounded-full\"></span></span>"
     ]}
  end

  defp render_node(%{node: {:slider, opts, nil}}) do
    class = class_with_default(opts, :slider)
    min = Keyword.get(opts, :min, 0)
    max = Keyword.get(opts, :max, 100)
    value = Keyword.get(opts, :value, min)
    step = Keyword.get(opts, :step, 1)

    ev_attr =
      case Keyword.get(opts, :on_change) do
        nil -> ""
        ev -> ~s( phx-change="#{ev}")
      end

    {:safe,
     [
       "<input type=\"range\" class=\"",
       class,
       "\" min=\"",
       to_string(min),
       "\" max=\"",
       to_string(max),
       "\" step=\"",
       to_string(step),
       "\" value=\"",
       to_string(value),
       "\"",
       ev_attr,
       ">"
     ]}
  end

  defp render_node(%{node: {:datepicker, opts, nil}}) do
    class = class_with_default(opts, :datepicker)
    value = Keyword.get(opts, :value)

    value_str =
      case value do
        %Date{} = d -> Date.to_iso8601(d)
        str when is_binary(str) -> str
        _ -> ""
      end

    ev_attr =
      case Keyword.get(opts, :on_change) do
        nil -> ""
        ev -> ~s( phx-change="#{ev}")
      end

    {:safe,
     [
       "<input type=\"date\" class=\"",
       class,
       "\" value=\"",
       escape_attr(value_str),
       "\"",
       ev_attr,
       ">"
     ]}
  end

  defp render_node(%{node: {:submit, opts, label}}) do
    class = class_with_default(opts, :submit)
    attrs = build_attrs(class, opts, [:class, :id, :type, :disabled])
    {:safe, ["<button type=\"submit\"", attrs, ">", escape_html(label), "</button>"]}
  end

  # ---------------------------------------------------------------------------
  # New components — navigation
  # ---------------------------------------------------------------------------

  defp render_node(%{node: {:menu, opts, children}}) do
    class = class_with_default(opts, :menu)
    orientation = Keyword.get(opts, :orientation, :horizontal)

    full =
      if orientation == :vertical,
        do: "#{class} flex-col items-stretch" |> String.trim(),
        else: class

    html_tag = if orientation == :vertical, do: :ul, else: :div
    html(html_tag, [class: full], Enum.map(children_to_list(children), &render_child/1))
  end

  defp render_node(%{node: {:breadcrumb, opts, items}}) do
    class = class_with_default(opts, :breadcrumb)

    rendered =
      items
      |> Enum.with_index()
      |> Enum.map(fn {item, idx} ->
        last = idx == length(items) - 1
        node_html = render_node(%{node: item})
        sep = if last, do: "", else: ~s(<span class="text-gray-400">/</span>)
        {:safe, [node_html, sep]}
      end)

    {:safe, ["<nav class=\"", class, "\">", rendered, "</nav>"]}
  end

  defp render_node(%{node: {:pagination, opts, nil}}) do
    class = class_with_default(opts, :pagination)
    current = Keyword.get(opts, :current_page, 1)
    total = Keyword.get(opts, :total_pages, 1)
    on_change = Keyword.get(opts, :on_change)

    ev = if on_change, do: ~s( phx-change="#{on_change}"), else: ""

    page_btn = fn n ->
      active = if n == current, do: " bg-blue-500 text-white", else: " bg-white"

      {:safe,
       [
         "<button class=\"px-2 py-1 border rounded",
         active,
         "\" data-page=\"",
         to_string(n),
         "\"",
         ev,
         ">",
         to_string(n),
         "</button>"
       ]}
    end

    buttons =
      [
        page_btn.(max(current - 1, 1)),
        page_btn.(current),
        page_btn.(min(current + 1, total))
      ]

    {:safe, ["<div class=\"", class, "\">", buttons, "</div>"]}
  end

  defp render_node(%{node: {:tabs, opts, nil}}) do
    class = class_with_default(opts, :tabs)
    tabs = Keyword.get(opts, :tabs, [])
    active = Keyword.get(opts, :active)
    on_change = Keyword.get(opts, :on_change)
    ev = if on_change, do: ~s( phx-change="#{on_change}"), else: ""

    rendered =
      tabs
      |> Enum.map(fn {key, label} ->
        active_cls =
          if key == active, do: " border-b-2 border-blue-500 font-medium", else: " text-gray-600"

        {:safe,
         [
           "<button class=\"px-4 py-2",
           active_cls,
           "\" data-tab=\"",
           escape_attr(to_string(key)),
           "\"",
           ev,
           ">",
           escape_html(label),
           "</button>"
         ]}
      end)

    {:safe, ["<div class=\"", class, "\">", rendered, "</div>"]}
  end

  defp render_node(%{node: {:navbar, opts, children}}) do
    class = class_with_default(opts, :navbar)
    html(:nav, [class: class], Enum.map(children_to_list(children), &render_child/1))
  end

  defp render_node(%{node: {:stepper, opts, nil}}) do
    class = class_with_default(opts, :stepper)
    steps = Keyword.get(opts, :steps, [])
    active = Keyword.get(opts, :active, 0)
    on_change = Keyword.get(opts, :on_change)
    ev = if on_change, do: ~s( phx-change="#{on_change}"), else: ""

    rendered =
      steps
      |> Enum.with_index()
      |> Enum.map(fn {label, idx} ->
        done = idx < active
        current = idx == active

        circle_cls =
          cond do
            done -> "bg-green-500 text-white"
            current -> "bg-blue-500 text-white"
            true -> "bg-gray-200 text-gray-600"
          end

        connector =
          if idx < length(steps) - 1,
            do: "<div class=\"flex-1 h-px bg-gray-300 mx-2\"></div>",
            else: ""

        {:safe,
         [
           "<div class=\"flex items-center\"><div class=\"w-8 h-8 rounded-full flex items-center justify-center text-sm",
           circle_cls,
           "\">",
           to_string(idx + 1),
           "</div><span class=\"ml-2 text-sm\">",
           escape_html(to_string(label)),
           "</span></div>",
           connector
         ]}
      end)

    {:safe, ["<div class=\"", class, "\">", rendered, "</div>"]}
  end

  # ---------------------------------------------------------------------------
  # New components — data display
  # ---------------------------------------------------------------------------

  defp render_node(%{node: {:stat, opts, %{label: label, value: value}}}) do
    class = class_with_default(opts, :stat)
    trend = Keyword.get(opts, :trend)

    trend_node =
      case trend do
        :up -> {:safe, ["<span class=\"text-green-500 text-sm\">\u2191</span>"]}
        :down -> {:safe, ["<span class=\"text-red-500 text-sm\">\u2193</span>"]}
        _ -> ""
      end

    {:safe,
     [
       "<div class=\"",
       class,
       "\"><div class=\"text-sm text-gray-500\">",
       escape_html(to_string(label)),
       "</div><div class=\"text-2xl font-semibold mt-1\">",
       escape_html(to_string(value)),
       " ",
       trend_node,
       "</div></div>"
     ]}
  end

  defp render_node(%{node: {:timeline, opts, events}}) do
    class = class_with_default(opts, :timeline)

    rendered =
      Enum.map(events, fn ev ->
        when_str =
          Map.get(ev, :date, Map.get(ev, :when, ""))
          |> to_string()

        what_str =
          Map.get(ev, :event, Map.get(ev, :what, ""))
          |> to_string()

        {:safe,
         [
           "<div class=\"relative\"><div class=\"absolute -left-6 w-3 h-3 bg-blue-500 rounded-full\"></div><div class=\"text-xs text-gray-500\">",
           escape_html(when_str),
           "</div><div class=\"text-sm\">",
           escape_html(what_str),
           "</div></div>"
         ]}
      end)

    {:safe, ["<div class=\"", class, "\">", rendered, "</div>"]}
  end

  defp render_node(%{node: {:avatar, opts, src}}) do
    class = class_with_default(opts, :avatar)
    name = Keyword.get(opts, :name, "")

    initials =
      name
      |> String.split(" ", trim: true)
      |> Enum.map_join("", &String.first/1)
      |> String.upcase()

    if src && src != "" do
      {:safe,
       [
         "<img src=\"",
         escape_attr(src),
         "\" class=\"",
         class,
         "\" alt=\"",
         escape_attr(name),
         "\">"
       ]}
    else
      {:safe,
       ["<div class=\"", class, "\" data-name=\"", escape_attr(name), "\">", initials, "</div>"]}
    end
  end

  defp render_node(%{node: {:tree, opts, items}}) do
    class = class_with_default(opts, :tree)
    expanded = Keyword.get(opts, :expanded, [])

    rendered = render_tree_items(items, expanded, 0)

    {:safe, ["<ul class=\"", class, "\">", rendered, "</ul>"]}
  end

  defp render_tree_items(items, expanded, depth) do
    Enum.map(items, fn item ->
      key = Map.get(item, :key)
      label = Map.get(item, :label, "")
      children = Map.get(item, :children, [])
      is_expanded = key in expanded

      chevron = tree_chevron(children != [], is_expanded)
      children_html = tree_children_html(children, expanded, depth, is_expanded)

      {:safe,
       [
         "<li><div class=\"flex items-center py-0.5\">",
         chevron,
         escape_html(to_string(label)),
         "</div>",
         children_html,
         "</li>"
       ]}
    end)
  end

  defp tree_chevron(false, _is_expanded),
    do: "<span class=\"mr-1\"></span>"

  defp tree_chevron(true, true),
    do: ~s(<span class="text-gray-400 mr-1">\u25BE</span>)

  defp tree_chevron(true, false),
    do: ~s(<span class="text-gray-400 mr-1">\u25B8</span>)

  defp tree_children_html([], _expanded, _depth, _is_expanded), do: ""

  defp tree_children_html(children, expanded, depth, true) do
    {:safe,
     [
       "<ul class=\"ml-4\">",
       render_tree_items(children, expanded, depth + 1),
       "</ul>"
     ]}
  end

  defp tree_children_html(_children, _expanded, _depth, false), do: ""

  # ---------------------------------------------------------------------------
  # New components — feedback / states
  # ---------------------------------------------------------------------------

  defp render_node(%{node: {:progress, opts, fraction}}) do
    class = class_with_default(opts, :progress)
    pct = max(0, min(100, fraction * 100))
    label = Keyword.get(opts, :label)

    label_node =
      if label,
        do:
          {:safe,
           [
             "<div class=\"flex justify-between text-xs mb-1\"><span>",
             escape_html(to_string(label)),
             "</span><span>",
             :erlang.float_to_binary(pct / 1.0, decimals: 0),
             "%</span></div>"
           ]},
        else: ""

    {:safe,
     [
       label_node,
       "<div class=\"",
       class,
       "\"><div class=\"h-full bg-blue-500\" style=\"width: ",
       :erlang.float_to_binary(pct, decimals: 1),
       "%\"></div></div>"
     ]}
  end

  defp render_node(%{node: {:alert, opts, message}}) do
    class = class_with_default(opts, :alert)
    tone = Keyword.get(opts, :tone, :info)
    title = Keyword.get(opts, :title)

    tone_class =
      case tone do
        :success -> "bg-green-50 border-green-200 text-green-800"
        :warning -> "bg-yellow-50 border-yellow-200 text-yellow-800"
        :error -> "bg-red-50 border-red-200 text-red-800"
        :info -> "bg-blue-50 border-blue-200 text-blue-800"
        _ -> "bg-gray-50 border-gray-200 text-gray-800"
      end

    title_node =
      if title,
        do:
          {:safe,
           [
             "<div class=\"font-semibold mb-1\">",
             escape_html(to_string(title)),
             "</div>"
           ]},
        else: ""

    full_class = "#{class} #{tone_class}" |> String.trim()

    {:safe,
     [
       "<div class=\"",
       full_class,
       "\" role=\"alert\">",
       title_node,
       escape_html(message),
       "</div>"
     ]}
  end

  defp render_node(%{node: {:toast, opts, message}}) do
    class = class_with_default(opts, :toast)
    tone = Keyword.get(opts, :tone, :info)

    tone_class =
      case tone do
        :success -> "border-green-300"
        :error -> "border-red-300"
        :warning -> "border-yellow-300"
        _ -> "border-blue-300"
      end

    full_class = "#{class} #{tone_class}" |> String.trim()
    {:safe, ["<div class=\"", full_class, "\" role=\"status\">", escape_html(message), "</div>"]}
  end

  defp render_node(%{node: {:skeleton, opts, nil}}) do
    class = class_with_default(opts, :skeleton)
    width = Keyword.get(opts, :width, "100%")
    height = Keyword.get(opts, :height, "1em")

    {:safe,
     [
       "<div class=\"",
       class,
       "\" style=\"width: ",
       escape_attr(to_string(width)),
       "; height: ",
       escape_attr(to_string(height)),
       ";\"></div>"
     ]}
  end

  defp render_node(%{node: {:notification, opts, message}}) do
    class = class_with_default(opts, :notification)
    unread = Keyword.get(opts, :unread, false)

    dot =
      if unread,
        do: "<span class=\"inline-block w-2 h-2 bg-blue-500 rounded-full mr-2\"></span>",
        else: ""

    {:safe, ["<div class=\"", class, "\">", {:safe, [dot]}, escape_html(message), "</div>"]}
  end

  # ---------------------------------------------------------------------------
  # Loader-aware data components — delegate to Flotilla.Loader when present
  # ---------------------------------------------------------------------------

  defp render_node(%{node: {:table, opts, rows}}) do
    class = class_with_default(opts, :table)
    columns = Keyword.get(opts, :columns, [])

    resolved_rows =
      if loader = Keyword.get(opts, :loader) do
        # `loader` is invoked once per row with the raw item; the result
        # is what we render in that row. We map sequentially by default;
        # for parallel resolution use the explicit `parallel:` opt.
        case Keyword.get(opts, :parallel, false) do
          true -> Flotilla.Loader.run_or_sequential(Enum.map(rows, loader))
          _ -> Enum.map(rows, loader)
        end
      else
        rows
      end

    headers = render_table_headers(columns)
    body = render_table_rows(resolved_rows, columns)

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

    resolved =
      if loader = Keyword.get(opts, :loader) do
        case Keyword.get(opts, :parallel, false) do
          true -> Flotilla.Loader.run_or_sequential(Enum.map(items, loader))
          _ -> Enum.map(items, loader)
        end
      else
        items
      end

    rendered =
      Enum.map(resolved, fn item ->
        rendered_item(item_fun, item)
      end)

    {:safe, ["<ul class=\"", class, "\">", rendered, "</ul>"]}
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
    {:safe,
     [
       "<",
       Atom.to_string(tag_atom),
       attrs_to_safe_string(attrs),
       ">",
       children,
       "</",
       Atom.to_string(tag_atom),
       ">"
     ]}
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
      cells = Enum.map(columns, fn col -> cell_html(cell_value(row, col)) end)
      {:safe, ["<tr>", cells, "</tr>"]}
    end)
  end

  defp cell_value(row, col) when is_map(row) and is_atom(col), do: Map.get(row, col, "")
  defp cell_value(row, col) when is_map(row) and is_binary(col), do: Map.get(row, col, "")

  defp cell_value(row, col) when is_list(row) and is_integer(col),
    do: row |> Enum.at(col, "") |> to_string()

  defp cell_value(_row, _col), do: ""

  defp cell_html(value) do
    {:safe, ["<td>", escape_html(to_string(value)), "</td>"]}
  end

  defp rendered_item(nil, item), do: escape_html(to_string(item))
  defp rendered_item(fun, item) when is_function(fun, 1), do: render_node(%{node: fun.(item)})
end
