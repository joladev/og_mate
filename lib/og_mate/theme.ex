defmodule OGMate.Theme do
  @schema [
    background: [type: :string, required: true],
    foreground: [type: :string, required: true],
    font: [type: :string, required: true],
    secondary: [type: :string, required: true],
    logo: [type: :string],
    site_name: [type: :string]
  ]

  @moduledoc """
  Theme for OG image rendering.

  ## Options

  #{NimbleOptions.docs(@schema)}
  """

  @enforce_keys [:background, :foreground, :font, :secondary]
  defstruct [:background, :foreground, :font, :secondary, :logo, :site_name]

  @type t() :: %__MODULE__{
          background: String.t(),
          foreground: String.t(),
          font: String.t(),
          secondary: String.t(),
          logo: String.t() | nil,
          site_name: String.t() | nil
        }

  @doc "Schema for theme keys. Exposed for embedding in other NimbleOptions schemas."
  def schema, do: @schema

  @doc "Validate a theme keyword list, return a `%OGMate.Theme{}` struct."
  @spec validate!(keyword()) :: t()
  def validate!(theme) when is_list(theme) do
    validated = NimbleOptions.validate!(theme, @schema)
    struct!(__MODULE__, validated)
  end
end
