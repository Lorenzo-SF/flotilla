defmodule Flotilla.Loader do
  @moduledoc """
  Optional bridge to `Arrea` for parallel data loading inside components.

  Lets declarative components fetch their data without blocking the
  render thread. Used by `Flotilla.Components.async_list/2`,
  `async_table/2`, and any future component that takes a `:loader`
  option.

  When `Arrea` is not loaded, calling `run/2` returns
  `{:error, :arrea_not_available}` so the host app can decide what
  to do (e.g. fall back to a synchronous loader).
  """

  @doc "Returns true if `Arrea.run_sync/2` is available."
  @spec arrea_available?() :: boolean()
  def arrea_available? do
    Code.ensure_loaded?(Arrea) and function_exported?(Arrea, :run_sync, 2)
  end

  @doc """
  Runs a list of zero-arity functions in parallel.

  Each function is expected to return the data for one row of a
  list / table. If `Arrea` is not available, returns
  `{:error, :arrea_not_available}`.

  Mirrors `Arrea.run_sync/2`'s signature.
  """
  @spec run([(-> any()) | term()], keyword()) :: {:ok, [any()]} | {:error, term()}
  def run(loaders, opts \\ []) when is_list(loaders) do
    if arrea_available?() do
      Arrea.run_sync(loaders, opts)
    else
      {:error, :arrea_not_available}
    end
  end

  @doc """
  Like `run/2` but runs sequentially when Arrea is unavailable.
  Useful as a fallback in code paths that should still work without
  the parallel engine.
  """
  @spec run_or_sequential([(-> any())], keyword()) :: [any()]
  def run_or_sequential(loaders, opts \\ []) when is_list(loaders) do
    case run(loaders, opts) do
      {:ok, results} -> results
      _ -> Enum.map(loaders, fn fun -> fun.() end)
    end
  end
end
