defmodule Flotilla.CLI.Commands.Status do
  @moduledoc """
  `flotilla status [deploy-id]` — show deploy status.
  """

  def run(opts) do
    case get_arg(opts, :deploy_id) do
      nil -> show_all()
      id -> show_one(id)
    end
  end

  defp show_all do
    deploys = Flotilla.Deploy.list()

    if deploys == [] do
      IO.puts("No deploys.")
    else
      Enum.each(deploys, fn {id, status} -> IO.puts("#{id}\t#{status}") end)
    end

    :ok
  end

  defp show_one(id) do
    case Flotilla.Deploy.info(id) do
      nil -> IO.puts("Unknown deploy: #{id}")
      state -> IO.puts("#{id}: #{state.status} (started: #{state.started_at}, finished: #{state.finished_at})")
    end

    :ok
  end

  defp get_arg(opts, key) do
    cond do
      Map.get(opts, key) -> Map.get(opts, key)
      args = Map.get(opts, :_args, []) -> hd(args)
      true -> nil
    end
  end
end
