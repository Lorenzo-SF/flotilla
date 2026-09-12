defmodule Flotilla.CLI.Commands.Rollback do
  @moduledoc """
  `flotilla rollback <deploy-id>` — rollback a deploy.
  """

  def run(opts) do
    id = get_arg(opts, :deploy_id)

    case Flotilla.Deploy.rollback(id) do
      :ok -> IO.puts("Rolled back: #{id}")
      {:error, reason} -> IO.puts("Rollback failed: #{inspect(reason)}")
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
