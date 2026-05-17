defmodule OGMate do
  @moduledoc """
  Compile-time OG image generation for Elixir content sites.

  A NimblePublisher-style library that bakes PNG images at compile time.
  Always returns `{:ok, bytes}` — unknown slugs resolve to the default image.

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
  Returns a list of all slugs that should have images.

  These are enumerated and baked at compile time.
  """
  @callback all_keys() :: [String.t()]

  @doc """
  Given a slug, return `{title, description}`, or `:error` if the slug
  shouldn't produce an image.

  Slugs that return `:error` are listed by `all_keys/0` but are skipped
  during baking (they resolve to the default image at runtime).
  """
  @callback content_for(slug :: String.t()) :: {String.t(), String.t()} | :error

  @doc """
  Custom rendering escape hatch.

  Override this function to take full control. Receives the title and
  description for the current slug, plus the theme map. Must return a
  PNG binary wrapped in `{:ok, ...}` or `{:error, reason}`.

  If rendering fails (`{:error, _}`), the slug is skipped during baking.
  If not implemented, the default renderer is used.
  """
  @callback render(title :: String.t(), desc :: String.t(), theme()) ::
              {:ok, binary()} | {:error, term()}

  @doc """
  Returns the PNG bytes for `slug`.

  Always returns `{:ok, png_binary}`. Unknown slugs fall through to the
  pre-baked default image — never an error at the public API.
  """
  @callback image_for(slug :: String.t()) :: {:ok, binary()}

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
    {default_title, default_desc} = Keyword.fetch!(opts, :default)
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
                    unquote(default_desc),
                    @og_theme
                  )

      # ── Content images (baked in prod, lazy in dev) ──────────────
      @og_images if(not @og_dev_mode) do
        Map.new(all_keys(), fn slug ->
          case content_for(slug) do
            {t, d} ->
              case OGMate.__bake__(__MODULE__, t, d, @og_theme) do
                {:ok, bytes} -> {slug, bytes}
                {:error, _} -> :skip
              end

            :error ->
              :skip
          end
        end)
      end

      # ── Public API: total, never errors ──────────────────────────
      @doc "Returns the PNG bytes for `slug`. Unknown slugs resolve to the default."
      @spec image_for(String.t()) :: {:ok, binary()}
      def image_for(slug) do
        case @og_images do
          nil ->
            # Dev mode: render on demand
            {t, d} = content_for(slug)

            case OGMate.__bake__(__MODULE__, t, d, @og_theme) do
              {:ok, bytes} ->
                {:ok, bytes}

              {:error, reason} ->
                IO.warn("render failed for #{inspect(slug)}: #{inspect(reason)}, using default")
                {:ok, @og_default}
            end

          map ->
            case Map.fetch(map, slug) do
              {:ok, bytes} -> {:ok, bytes}
              :error -> {:ok, @og_default}
            end
        end
      end

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
  def __bake__(module, title, desc, theme) do
    case render(module, title, desc, theme) do
      {:ok, bytes} -> {:ok, bytes}
      {:error, reason} -> {:error, reason}
    end
  end

  # Internal dispatch: user render or default renderer.
  @spec render(module(), String.t(), String.t(), map()) ::
          {:ok, binary()} | {:error, term()}
  defp render(module, title, desc, theme) do
    if function_exported?(module, :render, 3) do
      module.render(title, desc, theme)
    else
      OGMate.Renderer.render(title, desc, theme)
    end
  end
end
