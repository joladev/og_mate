defmodule OGMate.Options do
  @schema [
    all_keys: [type: {:list, :string}, required: true],
    content_for: [type: :atom, required: true],
    default: [type: {:tuple, [:string, :string]}, required: true],
    theme: [type: :keyword_list, keys: OGMate.Theme.schema()],
    renderer: [type: :atom],
    dev_mode: [type: :boolean, default: false]
  ]

  @moduledoc """
  Validates and normalizes options passed to `use OGMate`.

  ## Options

  #{NimbleOptions.docs(@schema)}
  """

  @enforce_keys [:all_keys, :content_for, :default]
  defstruct [:all_keys, :content_for, :default, :dev_mode, :theme, :renderer]

  def validate!(opts) do
    validated = NimbleOptions.validate!(opts, @schema) |> Map.new()
    Code.ensure_compiled!(validated.content_for)
    {theme, renderer} = validate_render!(validated)

    %__MODULE__{
      all_keys: validated.all_keys,
      content_for: validated.content_for,
      default: validated.default,
      dev_mode: validated.dev_mode,
      theme: theme,
      renderer: renderer
    }
  end

  defp validate_render!(opts) do
    case {Map.fetch(opts, :theme), Map.fetch(opts, :renderer)} do
      {{:ok, theme_input}, :error} ->
        {struct!(OGMate.Theme, theme_input), nil}

      {:error, {:ok, renderer}} ->
        Code.ensure_compiled!(renderer)
        {nil, renderer}

      {{:ok, _}, {:ok, _}} ->
        raise ArgumentError, "OGMate: pass either :theme or :renderer, not both"

      {:error, :error} ->
        raise ArgumentError, "OGMate: must pass :theme or :renderer"
    end
  end
end
