# OGMate

An opinionated library for generating OG images for static and dynamic routes, mildly inspired by NimblePublisher.

OG, or Open Graph, images are shown by social media and chat apps as a preview image when sharing links, and although they don't do anything for SEO, they can make your links look more professional (or fun).

OGMate is designed specifically to reduce the lift to get OG images going for your Elixir blog or site, with an opinionated basic template. The library also provides escape hatches for setting up your own image generation and just using the boilerplate to organize things. It's agnostic to your actual routes and metadata, you provide the implementation for fetching image keys, titles, and descriptions.

For an end-to-end setup including a Plug, layout integration, and optional dev mode config, see the [Getting started guide](https://hexdocs.pm/og_mate/getting_started.html). Basic examples available below.

## Installation

```elixir
def deps do
  [
    {:og_mate, "~> 0.1.0"}
  ]
end
```

## Examples

Happy path example.

```elixir
defmodule MyApp.OGContent do
  def content_for("home"), do: {"MyApp", "Welcome."}
  def content_for("about"), do: {"About", "My cool site"}
  def content_for(_), do: :error
end

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
```

`MyApp.OGContent` exports `content_for/1` returning `{title, description}` for known keys or `:error` for unknown ones. Unknown keys resolve to the configured default image.

Or, replacing the template with your own renderer:

```elixir
defmodule MyApp.OGRenderer do
  def render(title, description) do
    # Build your own image, return {:ok, png_binary} or {:error, reason}
    # Use the code from OGMate.Renderer as inspiration!
  end
end

defmodule MyApp.OGImage do
  use OGMate,
    all_keys: ["home", "about"],
    content_for: MyApp.OGContent,
    renderer: MyApp.OGRenderer,
    default: {"MyApp", "A brief site description."}
end
```

You can either set `renderer` or `theme`, you can't set both.

## Theme

Required: `background`, `foreground`, `font`, `secondary`.
Optional: `logo` (path to image file), `site_name` (text shown next to logo).

See `OGMate.Theme` for the full spec.

## Dev mode

By default, all images are built at compile time. For local dev, set `dev_mode: true` to render on demand instead of building everything up front:

```elixir
use OGMate,
  all_keys: [...],
  content_for: MyApp.OGContent,
  theme: [...],
  default: {...},
  dev_mode: Application.compile_env(:my_app, :og_image_dev_mode, false)
```

In dev_mode, each `image_for/1` call invokes `content_for/1` and the renderer at runtime. New content in your `content_for` module is visible without expensive recompilations.

## Dependencies

The default renderer uses [`:image`](https://hex.pm/packages/image), which bundles precompiled libvips binaries, no additional install needed. However, any fonts you want to use have to exist on the machine that builds the images.
