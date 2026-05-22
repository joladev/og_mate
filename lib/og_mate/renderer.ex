defmodule OGMate.Renderer do
  @moduledoc """
  Default OG image renderer (1200×630).

  Layout:

      ┌──────────────────────────────┐
      │  [logo]  site_name           │  ← top-left, 80px padding
      │                              │
      │                              │
      │                              │
      │                              │
      │                              │
      │                              │
      │  Title (72px bold)           │  ← bottom y = 470
      │  Description (32px)          │  ← y = 500
      └──────────────────────────────┘

  Returns `{:ok, png_binary}` on success or `{:error, reason}` if any
  rendering step fails (font unavailable, image read failure, etc.).
  """

  alias OGMate.Theme

  # Canvas dimensions (OG standard)
  @width 1200
  @height 630

  # Layout constants
  @padding 80
  @logo_size 72
  @logo_gap 20
  @title_bottom_y 470
  @desc_y 500
  @title_size 72
  @desc_size 32
  @site_name_size 48

  @doc """
  Render title + description + logo + site_name into a 1200×630 PNG.

  Returns `{:ok, png_binary}` on success, or `{:error, reason}` if any
  rendering step fails.
  """
  @spec render(String.t(), String.t(), Theme.t()) :: {:ok, binary()} | {:error, term()}
  def render(title, description, theme = %Theme{}) do
    with {:ok, img} <-
           Image.new(@width, @height, color: theme.background),
         {:ok, img} <- render_logo(img, theme),
         {:ok, img} <- render_site_name(img, theme),
         {:ok, img} <- render_title(img, title, theme),
         {:ok, img} <- render_description(img, description, theme) do
      Image.write(img, :memory, suffix: ".png")
    end
  end

  # ── Title layer (bottom-aligned, 48px bold) ───────────────────────

  defp render_title(img, title, theme = %Theme{}) when is_binary(title) and title != "" do
    with {:ok, text_img} <-
           Image.Text.text(title,
             font: theme.font,
             font_size: @title_size,
             text_fill_color: theme.foreground,
             font_weight: :bold,
             width: @width - 2 * @padding
           ) do
      y = @title_bottom_y - Image.height(text_img)
      Image.compose(img, text_img, x: @padding, y: y, mode: "atop")
    end
  end

  # ── Logo layer ───────────────────────────────────────────────────

  defp render_logo(img, %Theme{logo: nil}), do: {:ok, img}

  defp render_logo(img, theme = %Theme{}) do
    with {:ok, data} <- File.read(theme.logo),
         {:ok, logo_img} <- Image.from_binary(data, width: @logo_size, height: @logo_size) do
      Image.compose(img, logo_img, x: @padding, y: @padding, mode: "atop")
    end
  end

  # ── site_name layer ────────────────────────────────────────────────

  defp render_site_name(img, %Theme{site_name: nil}), do: {:ok, img}

  defp render_site_name(img, theme = %Theme{}) do
    with {:ok, text_img} <-
           Image.Text.text(theme.site_name,
             font: theme.font,
             font_size: @site_name_size,
             font_weight: :bold,
             text_fill_color: theme.foreground
           ) do
      x = if theme.logo, do: @padding + @logo_size + @logo_gap, else: @padding
      y = @padding + div(@logo_size - Image.height(text_img), 2)

      Image.compose(img, text_img, x: x, y: y, mode: "atop")
    end
  end

  # ── Description layer (below title, 20px) ─────────────────────────

  defp render_description(img, description, theme = %Theme{})
       when is_binary(description) and description != "" do
    with {:ok, text_img} <-
           Image.Text.text(description,
             font: theme.font,
             font_size: @desc_size,
             text_fill_color: theme.secondary,
             width: @width - 2 * @padding
           ) do
      Image.compose(img, text_img, x: @padding, y: @desc_y, mode: "atop")
    end
  end

  defp render_description(img, _description, _theme), do: {:ok, img}
end
