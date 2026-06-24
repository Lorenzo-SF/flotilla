defmodule Flotilla do
  @moduledoc """
  Flotilla — Declarative wrapper for Phoenix LiveView.

  Build LiveView UIs as composable data structures following The Elm
  Architecture (`model → update → view`) instead of writing HEEx templates
  directly.

  See `Flotilla.View` for the main `use Flotilla.View` macro and
  `Flotilla.Components` for the helper functions used to build VDOM trees.

  ## Quick start

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

        @impl Flotilla.View.Behaviour
        def view(model) do
          col([
            row([
              button("−", msg: :decrement),
              text("#{model.count}"),
              button("+", msg: :increment)
            ]),
            if model.loading do
              spinner()
            else
              table(model.items, columns: [:id, :name, :status])
            end
          ])
        end
      end

  ## Why a wrapper?

  LiveView's HEEx templates are powerful but mix concerns: layout,
  events, and state shape are spread across `mount/3`, `handle_event/3`,
  and template files. Flotilla keeps all of that in a single module with
  pure-Elixir functions you can read top-to-bottom.
  """

  @doc """
  Returns the Flotilla version embedded in the Mix project.
  """
  @spec version() :: String.t()
  def version, do: Application.spec(:flotilla, :vsn) |> to_string()
end
