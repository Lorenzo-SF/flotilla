defmodule Flotilla.CLI.Commands.Plan do
  @moduledoc """
  `flotilla plan <file>` — show a deployment plan from a JSON file.
  """

  def run(opts) do
    file = get_arg(opts, :file)

    with {:ok, json} <- File.read(file),
         {:ok, plan} <- decode(json),
         :ok <- print_plan(plan) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode(json) do
    decoded = Jason.decode!(json)
    {:ok, decoded}
  rescue
    e -> {:error, {:invalid_json, Exception.message(e)}}
  end

  defp print_plan(plan) do
    IO.puts("Plan: #{plan["name"] || "(unnamed)"}")
    IO.puts("  Artefact: #{plan["artefact"]["type"]}:#{plan["artefact"]["ref"] || plan["artefact"]["path"]}")
    IO.puts("  Strategy: #{plan["strategy"] || "immediate"}")
    IO.puts("  Targets:")

    for target <- plan["targets"] do
      IO.puts("    - #{target["type"]}:#{target["host"] || target["context"] || "?"} #{target["name"] || ""}")
    end

    :ok
  end

  defp get_arg(opts, key), do: Map.get(opts, key) || hd(Map.get(opts, :_args, []))
end
