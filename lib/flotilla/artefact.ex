defmodule Flotilla.Artefact do
  @moduledoc """
  Represents a deployable artefact.

  ## Types

    * `:binary` — local tarball/zip with binary release.
    * `:docker_image` — Docker image (ref like `myapp:1.2.3`).
    * `:release` — Elixir release directory (after `mix release`).
    * `:source` — git ref to build on the target.
  """

  defstruct [:type, :ref, :path, :checksum, :metadata]

  @type t :: %__MODULE__{
          type: :binary | :docker_image | :release | :source,
          ref: String.t() | nil,
          path: String.t() | nil,
          checksum: String.t() | nil,
          metadata: map()
        }

  @doc """
  Builds an artefact descriptor from a map of options.

  ## Options

    * `:type` — required, one of `:binary | :docker_image | :release | :source`.
    * `:ref` — reference (image:tag, git SHA, etc).
    * `:path` — local path for `:binary` or `:release`.
    * `:checksum` — SHA256 hex.
    * `:metadata` — arbitrary additional info.
  """
  @spec from_keyword(keyword()) :: t()
  def from_keyword(opts) do
    %__MODULE__{
      type: Keyword.fetch!(opts, :type),
      ref: Keyword.get(opts, :ref),
      path: Keyword.get(opts, :path),
      checksum: Keyword.get(opts, :checksum),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Validates the artefact has the required fields for its type.

  Returns `:ok` or `{:error, reason}`.
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{type: :docker_image, ref: nil}), do: {:error, "docker_image needs :ref"}
  def validate(%__MODULE__{type: :source, ref: nil}), do: {:error, "source needs :ref (git SHA)"}
  def validate(%__MODULE__{type: type}) when type not in [:binary, :docker_image, :release, :source] do
    {:error, "invalid type: #{inspect(type)}"}
  end
  def validate(%__MODULE__{type: type, path: nil}) when type in [:binary, :release] do
    {:error, "#{type} needs :path"}
  end
  def validate(%__MODULE__{type: _type}), do: :ok

  @doc """
  Returns a string identifier for this artefact (used in logs).
  """
  @spec id(t()) :: String.t()
  def id(%__MODULE__{type: :docker_image, ref: ref}), do: "docker:#{ref}"
  def id(%__MODULE__{type: :source, ref: ref}), do: "git:#{ref}"
  def id(%__MODULE__{type: type, path: path}), do: "#{type}:#{path}"
end
