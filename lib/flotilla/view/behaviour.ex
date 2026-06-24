defmodule Flotilla.View.Behaviour do
  @moduledoc """
  Behaviour that every `Flotilla.View` module must implement.

  The three callbacks map directly onto The Elm Architecture:

  1. `model/3` — initial state (called from `mount/3`)
  2. `update/2` — pure state transition (called from `handle_event/3`)
  3. `view/1` — render state as a VDOM tree (called from `render/1`)

  The `use Flotilla.View` macro wires all of these up so you only
  implement the callbacks, never the LiveView plumbing.
  """

  @typedoc """
  The application model — any term (typically a map) returned by `model/3`
  and passed through `update/2` and `view/1`.
  """
  @type model :: term()

  @typedoc """
  The message type handled by `update/2`. Can be any term; the macro
  converts string event names to existing atoms safely (no DoS).
  """
  @type msg :: term()

  @typedoc """
  The VDOM tree returned by `view/1`. See `Flotilla.Components` for the
  builder helpers and `Flotilla.VDOM` for the raw tagged tuple shape.
  """
  @type vdom :: term()

  @doc """
  Initial model state, computed once per LiveView mount.

  Receives the same `params`, `session`, and `socket` that
  `Phoenix.LiveView.mount/3` receives, so you can read URL params, the
  session, or the connected socket to build the initial state.
  """
  @callback model(
              params :: map(),
              session :: map(),
              socket :: Phoenix.LiveView.Socket.t()
            ) :: model()

  @doc """
  Pure state transition. Receives the current model and a message (the
  second element of a `phx-click` value, the value of an `on_change`, etc.)
  and returns the new model.

  Must be total: handle every message your view emits, or use
  `c:update/2` clauses with pattern matching.
  """
  @callback update(msg(), model()) :: model()

  @doc """
  Render the model as a VDOM tree. Called from `render/1`.

  The returned tree is passed through `Flotilla.Renderer.to_heex/1`.
  """
  @callback view(model()) :: vdom()
end
