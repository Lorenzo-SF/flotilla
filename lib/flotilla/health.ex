defmodule Flotilla.Health do
  @moduledoc """
  Health checks for Flotilla deploys.

  A health check is a small spec describing how to verify a deployment
  succeeded. Types:

    * `:http` — GET a URL, expect 2xx.
    * `:tcp` — connect to a host:port, expect connection.
    * `:command` — run a command, expect exit 0.

  ## Usage

      check = %Flotilla.Health.Spec{type: :http, url: "https://srv1.example.com/health"}
      Flotilla.Health.run(check, timeout_ms: 5_000)

  ## Integration with Trebejo

  When `trebejo` is available, `Flotilla.Health.run/2` delegates:
    * `:http` → `Trebejo.Network.http_check/2` (via Req).
    * `:tcp` → `Trebejo.Network.tcp_check/2`.
    * `:command` → `Arrea.Command.execute/2`.
  """

  defmodule Spec do
    @moduledoc false

    defstruct [:type, :url, :host, :port, :command, :args, :expected_status, :retries]

    @type t :: %__MODULE__{
            type: :http | :tcp | :command,
            url: String.t() | nil,
            host: String.t() | nil,
            port: pos_integer() | nil,
            command: String.t() | nil,
            args: [String.t()],
            expected_status: [non_neg_integer()],
            retries: non_neg_integer()
          }

    def build(opts) do
      %__MODULE__{
        type: Keyword.fetch!(opts, :type),
        url: Keyword.get(opts, :url),
        host: Keyword.get(opts, :host),
        port: Keyword.get(opts, :port),
        command: Keyword.get(opts, :command),
        args: Keyword.get(opts, :args, []),
        expected_status: Keyword.get(opts, :expected_status, [200]),
        retries: Keyword.get(opts, :retries, 2)
      }
    end
  end

  @type spec :: Spec.t()

  @default_timeout_ms 5_000

  @doc """
  Runs a health check with options.

  Options:
    * `:timeout_ms` — max time before giving up (default 5_000).
    * `:retries` — override retries from spec.

  Returns `:ok` or `{:error, reason}`.
  """
  @spec run(spec(), keyword()) :: :ok | {:error, term()}
  def run(%Spec{type: :http} = spec, opts) do
    http_check(spec, opts)
  end

  def run(%Spec{type: :tcp} = spec, opts) do
    tcp_check(spec, opts)
  end

  def run(%Spec{type: :command} = spec, opts) do
    command_check(spec, opts)
  end

  # ── implementations ────────────────────────────────────────────

  defp http_check(%Spec{url: url, expected_status: statuses}, opts) do
    timeout = Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    retries = Keyword.get(opts, :retries, 2)

    do_http_check(url, statuses, retries, timeout)
  end

  defp do_http_check(url, statuses, retries, timeout) do
    case Req.get(url, receive_timeout: timeout) do
      {:ok, %{status: status}} when status in statuses -> :ok
      {:ok, %{status: status}} -> {:error, {:unexpected_status, status}}
      {:error, reason} when retries > 0 ->
        Process.sleep(:timer.seconds(1))
        do_http_check(url, statuses, retries - 1, timeout)
      {:error, reason} -> {:error, reason}
    end
  end

  defp tcp_check(%Spec{host: host, port: port}, opts) do
    timeout = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    case :gen_tcp.connect(String.to_charlist(host), port, [:binary, active: false], timeout) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp command_check(%Spec{command: cmd, args: args}, opts) do
    timeout = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    Code.ensure_loaded?(Arrea.Command)
    Code.ensure_loaded?(Arrea)

    cond do
      Code.ensure_loaded?(Arrea) and function_exported?(Arrea, :command, 1) ->
        arrea_check(cmd, args, timeout)
      true ->
        fallback_check(cmd, args, timeout)
    end
  end

  defp arrea_check(cmd, args, timeout) do
    try do
      Arrea.Command.execute({cmd, args}, timeout: timeout)
    rescue
      _ -> fallback_check(cmd, args, timeout)
    end
  end

  defp fallback_check(cmd, args, timeout) do
    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {output, code} -> {:error, {:exit, code, output}}
    end
  rescue
    e -> {:error, e}
  catch
    :exit, reason when is_integer(timeout) and timeout < :infinity ->
      {:error, {:timeout, reason}}
  end

  # Backwards compat alias for callers using Spec directly.
  @doc false
  defdelegate build(opts), to: Spec, as: :build
end
