ExUnit.start()

# Renderer tests require Phoenix.LiveView. If it's not loaded (because
# it's optional: true in mix.exs), skip them gracefully.
case Code.ensure_loaded(Phoenix.LiveView) do
  {:module, _} ->
    :ok

  _ ->
    ExUnit.configure(exclude: [:requires_live_view], include: [])
end
