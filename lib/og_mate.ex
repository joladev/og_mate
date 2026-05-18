defmodule OGMate do
  @moduledoc """
  Compile-time OG image generation for Elixir content sites.

  A NimblePublisher-style library that bakes PNG images at compile time.
  Always returns `{:ok, bytes}` — unknown keys resolve to the default image.

  ## Example

      defmodule MyApp.OGImage do
        use OGMate,
          theme: [
            background: "#0a0a0a",
            foreground: "white",
            muted: "#a3a3a3",
            font: "Inter",
            logo: "priv/static/images/logo.png",
            wordmark: "myapp.com"
          ],
          default: {"MyApp", "A brief site description."}

        @impl OGMate
        def all_keys, do: ["home", "about"]

        @impl OGMate
        def content_for("home"), do: {"MyApp", "Welcome."}
        def content_for("about"), do: {"About", "..."}
      end

      {:ok, png} = MyApp.OGImage.image_for("home")

  ## Custom Templates

  If the default layout doesn't fit your site, implement `render/3` on your module:

      defmodule MyApp.OGImage do
        use OGMate, theme: [...], default: {...}

        @impl OGMate
        def render(title, desc, theme) do
          # Full control: Image.New! → Image.Draw → Image.Text → Image.compose → Image.write
          # Return {:ok, png_binary} or {:error, reason}
        end
      end
  """

  @typedoc "The theme map passed to render callbacks."
  @type theme() :: %{
          optional(:background) => String.t(),
          optional(:foreground) => String.t(),
          optional(:muted) => String.t(),
          optional(:font) => String.t(),
          optional(:logo) => String.t() | nil,
          optional(:wordmark) => String.t() | nil
        }

  # ── Callbacks ────────────────────────────────────────────────────

  @doc """
  Returns a list of all keys that should have images.

  These are enumerated and baked at compile time.
  """
  @callback all_keys() :: [String.t()]

  @doc """
  Given a key, return `{title, description}`, or `:error` if the key
  shouldn't produce an image.

  keys that return `:error` are listed by `all_keys/0` but are skipped
  during baking (they resolve to the default image at runtime).
  """
  @callback content_for(key :: String.t()) :: {String.t(), String.t()} | :error

  @doc """
  Custom rendering escape hatch.

  Override this function to take full control. Receives the title and
  description for the current key, plus the theme map. Must return a
  PNG binary wrapped in `{:ok, ...}` or `{:error, reason}`.

  If rendering fails (`{:error, _}`), the key is skipped during baking.
  If not implemented, the default renderer is used.
  """
  @callback render(title :: String.t(), description :: String.t(), theme()) ::
              {:ok, binary()} | {:error, term()}

  @doc """
  Returns the PNG bytes for `key`.

  Always returns `{:ok, png_binary}`. Unknown keys fall through to the
  pre-baked default image — never an error at the public API.
  """
  @callback image_for(key :: String.t()) :: {:ok, binary()}

  @optional_callbacks render: 3

  # ── Using macro ──────────────────────────────────────────────────

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour OGMate
      @before_compile OGMate
      @og_opts opts
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :og_opts)

    theme = opts |> Keyword.fetch!(:theme) |> Map.new()
    {default_title, default_description} = Keyword.fetch!(opts, :default)
    dev_mode = Keyword.get(opts, :dev_mode, false)

    theme_code = Macro.escape(theme)
    dev_mode_code = Macro.escape(dev_mode)

    quote do
      @og_theme unquote(theme_code)
      @og_dev_mode unquote(dev_mode_code)

      # ── Always-baked default image (fixed cost, no data dependency) ──
      @og_default OGMate.__bake__(
                    __MODULE__,
                    unquote(default_title),
                    unquote(default_description),
                    @og_theme
                  )

      # ── Content images (baked in prod, lazy in dev) ──────────────
      @og_images if(not @og_dev_mode) do
        Map.new(all_keys(), fn key ->
          case content_for(key) do
            {title, description} ->
              case OGMate.__bake__(__MODULE__, title, description, @og_theme) do
                {:ok, bytes} -> {key, bytes}
                {:error, _} -> :skip
              end

            :error ->
              :skip
          end
        end)
      end

      # ── Public API: total, never errors ──────────────────────────
      @doc "Returns the PNG bytes for `key`. Unknown keys resolve to the default."
      @spec image_for(String.t()) :: {:ok, binary()}
      def image_for(key) do
        case @og_images do
          nil ->
            # Dev mode: render on demand
            {title, description} = content_for(key)

            case OGMate.__bake__(__MODULE__, title, description, @og_theme) do
              {:ok, bytes} ->
                {:ok, bytes}

              {:error, reason} ->
                IO.warn("render failed for #{inspect(key)}: #{inspect(reason)}, using default")
                {:ok, @og_default}
            end

          map ->
            case Map.fetch(map, key) do
              {:ok, bytes} -> {:ok, bytes}
              :error -> {:ok, @og_default}
            end
        end
      end

      @doc "Returns the pre-baked default PNG binary."
      def default_image(), do: @og_default

      # ── Recompile hook ───────────────────────────────────────────
      def __mix_recompile__(), do: all_keys()
    end
  end

  @doc """
  Bake an image from `{title, description}` + theme.

  Dispatches to the user's `render/3` (if implemented) or falls back
  to `OGMate.Renderer.render/3`. Always returns `{:ok, bytes}` or
  `{:error, reason}`.
  """
  @spec __bake__(module(), String.t(), String.t(), map()) ::
          {:ok, binary()} | {:error, term()}
  def __bake__(module, title, description, theme) do
    case render(module, title, description, theme) do
      {:ok, bytes} -> {:ok, bytes}
      {:error, reason} -> {:error, reason}
    end
  end

  # Internal dispatch: user render or default renderer.
  @spec render(module(), String.t(), String.t(), map()) ::
          {:ok, binary()} | {:error, term()}
  defp render(module, title, description, theme) do
    if function_exported?(module, :render, 3) do
      module.render(title, description, theme)
    else
      OGMate.Renderer.render(title, description, theme)
    end
  end
end
