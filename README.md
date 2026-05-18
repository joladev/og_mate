# OGMate

An opinionated library for generating OG images for static and dynamic routes, mildly inspired by NimblePublisher.

OG, or Open Graph, images are shown by social media and chat apps as a preview image when sharing links, and although they don't do anything for SEO, they can make your links look more professional (or fun).

OGMate is designed specifically to reduce the lift to get OG images going for your Elixir blog or site, with an opinionated basic template. The library also provides escape hatches for setting up your own image generation and just using the boilerplate to organize things. It's agnostic to your actual routes and metadata, and provide callbacks for you to implement instead.

## Installation

```elixir
def deps do
  [
    {:og_mate, "~> 0.1.0"}
  ]
end
```
