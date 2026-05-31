defmodule OGMate do
  @moduledoc """
  Builds PNG images at compile time from a user-provided key list and
  content function. Always returns `{:ok, bytes}` from `image_for/1`.
  Unknown keys resolve to the pre-built default image.

  ## Example

      defmodule MyApp.OGImage do
        use OGMate,
          all_keys: ["home", "about"],
          content_for: MyApp.OGContent,
          theme: [
            background: "#0a0a0a",
            foreground: "#ffffff",
            font: "Inter",
            secondary: "#a3a3a3",
            logo: "priv/static/images/logo.png",
            site_name: "myapp.com"
          ],
          default: {"MyApp", "A brief site description."}
      end

      {:ok, png} = MyApp.OGImage.image_for("home")

  ## Custom Renderer

  Pass a `renderer:` module that exports `render(title, description)`:

      defmodule MyApp.OGRenderer do
        def render(title, description), do: {:ok, png}
      end

      defmodule MyApp.OGImage do
        use OGMate,
          all_keys: [...],
          content_for: ...,
          renderer: MyApp.OGRenderer,
          default: {...}
      end

  `:theme` and `:renderer` are mutually exclusive.

  See `OGMate.Options` for the full option contract, and the
  [Getting started guide](getting_started.md) for end-to-end setup.
  """

  # ── Using macro ──────────────────────────────────────────────────

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @before_compile OGMate
      @og_opts opts
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :og_opts)
    options = OGMate.Options.validate!(opts)

    {default_title, default_description} = options.default

    default_bytes =
      OGMate.__render__!(options.theme, options.renderer, default_title, default_description)

    images =
      unless options.dev_mode do
        Map.new(options.all_keys, fn key ->
          {title, desc} = options.content_for.content_for(key)
          {key, OGMate.__render__!(options.theme, options.renderer, title, desc)}
        end)
      end

    quote do
      @og_default unquote(Macro.escape(default_bytes))
      @og_images unquote(Macro.escape(images))
      @og_content_for unquote(options.content_for)
      @og_theme unquote(Macro.escape(options.theme))
      @og_renderer unquote(Macro.escape(options.renderer))

      @spec image_for(String.t()) :: {:ok, binary()}
      def image_for(key) do
        with :error <- lookup(key) do
          {:ok, @og_default}
        end
      end

      def default_image, do: @og_default

      if @og_images do
        defp lookup(key) do
          Map.fetch(@og_images, key)
        end
      else
        defp lookup(key) do
          with {title, desc} <- @og_content_for.content_for(key) do
            {:ok, OGMate.__render__!(@og_theme, @og_renderer, title, desc)}
          end
        end
      end
    end
  end

  @doc false
  def __render__!(theme, renderer, title, desc) do
    result =
      case {theme, renderer} do
        {%OGMate.Theme{} = t, nil} -> OGMate.Renderer.render(title, desc, t)
        {nil, mod} when is_atom(mod) -> mod.render(title, desc)
      end

    case result do
      {:ok, bytes} -> bytes
      {:error, reason} -> raise "OGMate render failed: #{inspect(reason)}"
    end
  end
end
