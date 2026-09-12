defmodule Flotilla.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # The Deploy Agent starts lazily; no need for a supervised process in v1.
    ]

    opts = [strategy: :one_for_one, name: Flotilla.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
