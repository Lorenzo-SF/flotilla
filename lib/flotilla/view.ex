defmodule Flotilla.View do
  @moduledoc """
  `use Flotilla.View` — converts a module into a LiveView following
  The Elm Architecture.

  ## Generated callbacks

  The macro generates these `Phoenix.LiveView` callbacks:

  * `mount/3` — calls your `model/3`, stores it in `:__model__`
  * `handle_event/3` — string→atom + `update/2`, stores result back
  * `render/1` — calls your `view/1` + `Flotilla.Renderer.to_heex/1`

  You implement `Flotilla.View.Behaviour`'s three callbacks
  (`model/3`, `update/2`, `view/1`) and Flotilla wires the rest.

  ## Example

      defmodule MyAppWeb.CounterLive do
        use Flotilla.View

        @impl Flotilla.View.Behaviour
        def model(_, _, _), do: %{count: 0}

        @impl Flotilla.View.Behaviour
        def update(:increment, m), do: %{m | count: m.count + 1}
        def update(:decrement, m), do: %{m | count: m.count - 1}
        def update(_, m), do: m

        @impl Flotilla.View.Behaviour
        def view(m) do
          row([
            button("−", msg: :decrement),
            text("\#{m.count}"),
            button("+", msg: :increment)
          ])
        end
      end
  """

  @doc """
  `use Flotilla.View` macro.

  Accepts the same options as `Phoenix.LiveView`'s `use` macro. Currently
  no extra options are consumed by Flotilla itself.
  """
  defmacro __using__(_opts) do
    quote do
      use Phoenix.LiveView
      @behaviour Flotilla.View.Behaviour

      @impl Phoenix.LiveView
      def mount(params, session, socket) do
        model = __MODULE__.model(params, session, socket)
        {:ok, Phoenix.Component.assign(socket, :__model__, model)}
      end

      @impl Phoenix.LiveView
      def handle_event(msg_str, _params, socket) do
        # String.to_existing_atom/1 — never creates atoms dynamically.
        # If the msg is unknown, fall back to the literal atom so the
        # user's update/2 can decide what to do.
        msg =
          try do
            String.to_existing_atom(msg_str)
          rescue
            ArgumentError -> msg_str
          end

        model = socket.assigns.__model__ |> __MODULE__.update(msg)
        {:noreply, Phoenix.Component.assign(socket, :__model__, model)}
      end

      @impl Phoenix.LiveView
      def render(assigns) do
        vdom = __MODULE__.view(assigns.__model__)
        Flotilla.Renderer.to_heex(vdom)
      end
    end
  end
end
