# Getting started

TL;DR: define a content module mapping keys to titles and descriptions, point OGMate at it, mount a plug to serve `/images/og/<key>.png`, drop a meta tag in your layout. Images are built at compile time and served straight from memory.

OG images are those preview cards you see when sharing links on social media. They don't help SEO but they make your links look intentional. OGMate handles the build pipeline, you provide the content.

This walks through the full setup, framework-agnostic. Works inside a Phoenix endpoint, but Phoenix isn't required.

## 1. Add the dependency

```elixir
def deps do
  [
    {:og_mate, "~> 0.1.0"}
  ]
end
```

## 2. Content module

Map URL slugs to `{title, description}`. Return `:error` for anything unknown, those fall through to the default image at runtime.

```elixir
defmodule MyApp.OGContent do
  @static_content %{
    "home" => {"MyApp", "Welcome to MyApp."},
    "about" => {"About", "What MyApp does."}
  }

  def content_for(key) when is_map_key(@static_content, key),
    do: Map.fetch!(@static_content, key)

  def content_for("posts/" <> id) do
    case MyApp.Blog.find_by_id(id) do
      nil -> :error
      post -> {post.title, post.description}
    end
  end

  def content_for(_), do: :error
end
```

Static map for fixed pages, pattern-matched clauses for dynamic content. The catch-all `:error` clause at the bottom handles anything the rest didn't.

## 3. The OGMate module

```elixir
defmodule MyApp.OGImage do
  use OGMate,
    all_keys:
      ["home", "about"] ++ Enum.map(MyApp.Blog.all_posts(), &"posts/#{&1.id}"),
    content_for: MyApp.OGContent,
    theme: [
      background: "#0a0a0a",
      foreground: "#ffffff",
      font: "Inter",
      secondary: "#a3a3a3",
      logo: "priv/static/images/logo.png",
      site_name: "myapp.com"
    ],
    default: {"MyApp", "Welcome to MyApp."},
    dev_mode: Application.compile_env(:my_app, :og_image_dev_mode, false)

  def path_for(key) when is_binary(key), do: "/images/og/#{key}.png"
end
```

`all_keys` is computed at compile time. `MyApp.Blog.all_posts()` is a normal call to an already-compiled module, the result gets inlined as a literal list. New posts means a recompile, but Phoenix code reloading handles that for you in dev.

`path_for/1` keeps URL building in one place so the plug and your templates stay in sync.

## 4. The plug

A small plug intercepts `/images/og/<key>.png` and serves the bytes.

```elixir
defmodule MyApp.Plugs.OGImage do
  @behaviour Plug
  import Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{request_path: "/images/og/" <> rest} = conn, _) do
    key = String.replace_suffix(rest, ".png", "")
    {:ok, bytes} = MyApp.OGImage.image_for(key)

    conn
    |> put_resp_content_type("image/png")
    |> put_resp_header("cache-control", "public, max-age=31536000")
    |> send_resp(200, bytes)
    |> halt()
  end

  def call(conn, _), do: conn
end
```

That `cache-control` is a year, which is fine because the URLs are content-keyed. If the content changes, the key changes.

## 5. Mount the plug

In Phoenix, drop it into the endpoint:

```elixir
# lib/my_app_web/endpoint.ex
plug MyApp.Plugs.OGImage
plug Plug.Static, ...
```

Before `Plug.Static` so OG requests are caught first. Outside Phoenix, add it to your `Plug.Router`.

## 6. Reference in your HTML

```html
<meta property="og:image" content={MyApp.OGImage.path_for(@og_key)} />
```

Set `@og_key` per route in your controller. `"home"` for the homepage, `"posts/#{post.id}"` for a post page.

## 7. Dev mode

Building everything at compile time is great for production. But rendering all your OG images on every save while you're iterating gets old fast. Set `dev_mode: true` and OGMate skips that at compile time, rendering lazily on each `image_for/1` call instead. New content shows up immediately, no recompile.

```elixir
# config/dev.exs
config :my_app, og_image_dev_mode: true
```

```elixir
# config/prod.exs
config :my_app, og_image_dev_mode: false
```

The `Application.compile_env(:my_app, :og_image_dev_mode, false)` call in step 3 reads this at compile time.

## See also

- `OGMate`: main module reference
- `OGMate.Theme`: theme field reference
- `OGMate.Renderer`: default renderer (1200×630 PNG layout)
