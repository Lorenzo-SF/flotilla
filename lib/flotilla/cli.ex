defmodule Flotilla.CLI do
  @moduledoc """
  Main CLI for Flotilla — uses `Alaja.CLI.Definition`.

  ## Commands

    * `flotilla plan <file>` — show a plan from a JSON file.
    * `flotilla deploy <file>` — run a deploy from a JSON file.
    * `flotilla status [deploy-id]` — show status of one or all deploys.
    * `flotilla rollback <deploy-id>` — rollback a deploy.
    * `flotilla version` — show version.
  """

  use Alaja.CLI.Definition, otp_app: :flotilla

  command "plan", "Show a plan from a JSON file" do
    argument :file, :string, required: true
    run fn opts -> Flotilla.CLI.Commands.Plan.run(opts) end
  end

  command "deploy", "Run a deploy from a JSON file" do
    argument :file, :string, required: true
    flag :dry_run, :boolean, default: false
    run fn opts -> Flotilla.CLI.Commands.Deploy.run(opts) end
  end

  command "status", "Show status of one or all deploys" do
    argument :deploy_id, :string, required: false
    run fn opts -> Flotilla.CLI.Commands.Status.run(opts) end
  end

  command "rollback", "Rollback a deploy" do
    argument :deploy_id, :string, required: true
    run fn opts -> Flotilla.CLI.Commands.Rollback.run(opts) end
  end

  command "version", "Show Flotilla version" do
    run fn _opts ->
      IO.puts("flotilla #{Flotilla.MixProject.version()}")
      :ok
    end
  end

  @doc """
  Entry point for escript.
  """
  def main(argv) do
    Definition.exec(argv)
  end
end
