defmodule Flotilla.Target do
  @moduledoc """
  Represents a single deployment target.

  Each target type has its own behaviour. The default implementations
  delegate to `trebejo` (when available) for the underlying operations.
  """

  defstruct [:type, :host, :context, :name, :metadata, :health_check]

  @type target_type :: :bare_metal | :docker | :kubernetes | :systemd_nspawn

  @type t :: %__MODULE__{
          type: target_type(),
          host: String.t() | nil,
          context: String.t() | nil,
          name: String.t() | nil,
          metadata: map(),
          health_check: Health.spec() | nil
        }

  @doc """
  Builds a target from a map.
  """
  @spec from_keyword(keyword()) :: t()
  def from_keyword(opts) do
    %__MODULE__{
      type: Keyword.fetch!(opts, :type),
      host: Keyword.get(opts, :host),
      context: Keyword.get(opts, :context),
      name: Keyword.get(opts, :name),
      metadata: Keyword.get(opts, :metadata, %{}),
      health_check: Keyword.get(opts, :health_check)
    }
  end

  @doc """
  Returns a unique identifier for the target (used in logs).
  """
  @spec id(t()) :: String.t()
  def id(%__MODULE__{type: :kubernetes, context: ctx} = t) do
    "k8s:#{ctx || "default"}:#{t.name || "unnamed"}"
  end
  def id(%__MODULE__{type: type, host: host} = t) do
    "#{type}:#{host || "local"}:#{t.name || "unnamed"}"
  end

  @doc """
  Validates the target has the required fields for its type.
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{type: type}) when type not in [:bare_metal, :docker, :kubernetes, :systemd_nspawn] do
    {:error, "invalid target type: #{inspect(type)}"}
  end
  def validate(%__MODULE__{type: :bare_metal, host: nil}), do: {:error, "bare_metal needs :host"}
  def validate(%__MODULE__{type: :kubernetes, context: nil}), do: {:error, "kubernetes needs :context"}
  def validate(%__MODULE__{type: :docker, host: nil}), do: {:error, "docker needs :host"}
  def validate(%__MODULE__{type: _type}), do: :ok
end
