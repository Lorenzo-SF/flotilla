defmodule Flotilla.CLI.Commands.Deploy do
  @moduledoc """
  `flotilla deploy <file>` — run a deployment from a JSON plan file.
  """

  def run(opts) do
    file = get_arg(opts, :file)
    dry_run = Map.get(opts, :dry_run, false)

    with {:ok, json} <- File.read(file),
         {:ok, plan_kw} <- decode(json),
         plan <- Flotilla.Plan.from_keyword(plan_kw),
         :ok <- maybe_dry_run(plan, dry_run),
         {:ok, deploy_id} <- Flotilla.Deploy.run(plan) do
      IO.puts("Deploy started: #{deploy_id}")
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode(json) do
    decoded = Jason.decode!(json)
    {:ok, decoded_atomized} = {:ok, atomize_keys(decoded)}
    {:ok, decoded_atomized}
  rescue
    e -> {:error, {:invalid_json, Exception.message(e)}}
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), atomize_keys(v)}
      {k, v} -> {k, atomize_keys(v)}
    end)
  end

  defp atomize_keys(list) when is_list(list), do: Enum.map(list, &atomize_keys/1)
  defp atomize_keys(v), do: v

  defp maybe_dry_run(_plan, false), do: :ok

  defp maybe_dry_run(plan, true) do
    IO.puts("[DRY RUN] Plan: #{plan.name}")
    IO.puts("  Would deploy to #{length(plan.targets)} target(s) using strategy #{plan.strategy}")
    :ok
  end

  defp get_arg(opts, key), do: Map.get(opts, key) || hd(Map.get(opts, :_args, []))
end
