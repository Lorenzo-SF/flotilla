defmodule Flotilla.Colors do
  @moduledoc """
  Optional bridge to `Pote` for color parsing in component options.

  This module is loaded unconditionally but only does work when
  `Pote` is present (i.e. the host app has added it as a dependency).
  When `Pote` is absent, the parsing helpers gracefully fall back to
  passing the input through as a CSS string, so callers can still
  write `:color` opts without crashing.

  ## Supported option keys

  Any component opts can carry these color keys. The renderer
  applies them to inline `style`:

    * `:color` — text color (`color: <rgb>`)
    * `:bg` — background color (`background-color: <rgb>`)
    * `:border` — border color (`border-color: <rgb>`)
    * `:ring` — focus ring color (`--tw-ring-color: <rgb>`)
    * `:fill` — fill color (for SVG / icons)

  Color values can be any of the formats `Pote.parse/1` understands:

      #FF0000                    # hex 6-digit
      #F00                       # hex 3-digit
      "rgb:255,0,0"              # explicit RGB
      "red", "blue", "tomato"    # CSS named colors
      "hsl:0,100,50"             # HSL
      "hsv:0,100,100"            # HSV
      "theme:primary"            # from the active Pote/Alaja theme

  ## Example

      col([text("Hi", color: "theme:primary")])
      card([text("OK", bg: "#00FF00")])
  """

  @doc "Returns true if `Pote` is loaded and `Pote.parse/1` is available."
  @spec pote_available?() :: boolean()
  def pote_available? do
    Code.ensure_loaded?(Pote) and function_exported?(Pote, :parse, 1)
  end

  @doc """
  Parses a color value to an `"rgb(r, g, b)"` CSS string.

  Falls back to the input verbatim if `Pote` is unavailable or
  parsing fails (so a bad color doesn't take down the whole UI).
  """
  @spec to_rgb_css(term()) :: String.t()
  def to_rgb_css(value) when is_binary(value) do
    if pote_available?() do
      try do
        case Pote.parse(value) do
          {:ok, {r, g, b}} -> "rgb(#{r}, #{g}, #{b})"
          {:error, _} -> value
        end
      catch
        _, _ -> value
      end
    else
      value
    end
  end

  def to_rgb_css(other), do: to_string(other)

  @doc """
  Converts a keyword list of color opts into a list of CSS
  `property: value` pairs suitable for a `style=` attribute.

  Recognized keys: `:color`, `:bg`, `:border`, `:ring`, `:fill`.
  Unknown keys are ignored.
  """
  @spec style_from_opts(keyword()) :: [{String.t(), String.t()}]
  def style_from_opts(opts) when is_list(opts) do
    Enum.reduce(opts, [], fn {key, value}, acc ->
      case key do
        :color -> [{"color", to_rgb_css(value)} | acc]
        :bg -> [{"background-color", to_rgb_css(value)} | acc]
        :border -> [{"border-color", to_rgb_css(value)} | acc]
        :ring -> [{"--tw-ring-color", to_rgb_css(value)} | acc]
        :fill -> [{"fill", to_rgb_css(value)} | acc]
        _ -> acc
      end
    end)
  end

  def style_from_opts(_), do: []

  @doc """
  Renders a `style="prop: val; prop2: val2"` string from opts.
  Returns `""` if no style-producing opts are present.
  """
  @spec style_attr(keyword()) :: String.t()
  def style_attr(opts) do
    pairs = style_from_opts(opts)

    if pairs == [] do
      ""
    else
      body =
        pairs
        |> Enum.map(fn {k, v} -> "#{k}: #{v};" end)
        |> Enum.join(" ")

      ~s(style="#{body}")
    end
  end
end