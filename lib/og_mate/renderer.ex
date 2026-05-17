defmodule OGMate.Renderer do
  @moduledoc """
  Default OG image renderer (1200×630).

  Layout:

      ┌──────────────────────────────┐
      │  [logo]  wordmark            │  ← top-left, 40px padding
      │                              │
      │                              │
      │                              │
      │                              │
      │                              │
      │                              │
      │  Title (48px bold)           │  ← y = 470
      │  Description (20px)          │  ← y = 500
      └──────────────────────────────┘

  Returns `{:ok, png_binary}` on success or `{:error, reason}` if any
  rendering step fails (font unavailable, image read failure, etc.).
  """

  # Canvas dimensions (OG standard)
  @width 1200
  @height 630

  # Layout constants
  @padding 40
  @logo_size 48
  @logo_gap 8
  @title_y 470
  @desc_y 500
  @title_size 48
  @desc_size 20
  @wordmark_size 24

  @doc """
  Render title + description + logo + wordmark into a 1200×630 PNG.

  Returns `{:ok, png_binary}` on success, or `{:error, reason}` if any
  rendering step fails.
  """
  @spec render(String.t(), String.t(), map()) :: {:ok, binary()} | {:error, term()}
  def render(title, desc, theme) do
    with {:ok, img} <-
           Image.new(@width, @height, color: Keyword.get(theme, :background, "#000000")),
         {:ok, img} <- render_logo(img, theme),
         {:ok, img} <- render_wordmark(img, theme),
         {:ok, img} <- render_title(img, title, theme),
         {:ok, img} <- render_desc(img, desc, theme),
         {:ok, png} <- Image.write(img, :memory, suffix: ".png") do
      {:ok, png}
    end
  end

  # ── Logo layer ───────────────────────────────────────────────────

  defp render_logo(img, %{logo: nil}), do: {:ok, img}

  defp render_logo(img, theme) do
    with {:ok, data} <- File.read(theme[:logo]),
         {:ok, logo_img} <- Image.from_binary(data, width: @logo_size, height: @logo_size),
         {:ok, result} <- Image.compose(img, logo_img, x: @padding, y: @padding, mode: "atop") do
      {:ok, result}
    end
  end

  # ── Wordmark layer ────────────────────────────────────────────────

  defp render_wordmark(img, %{wordmark: nil}), do: {:ok, img}

  defp render_wordmark(img, theme) do
    with {:ok, text_img} <-
           Image.Text.text(theme[:wordmark],
             font: Keyword.get(theme, :font, "Inter"),
             font_size: @wordmark_size,
             text_fill_color: Keyword.get(theme, :muted, "#a3a3a3")
           ) do
      Image.compose(img, text_img,
        x: @padding + @logo_size + @logo_gap,
        y: @padding,
        mode: "atop"
      )
    end
  end

  # ── Title layer (bottom-aligned, 48px bold) ───────────────────────

  defp render_title(img, title, theme) when is_binary(title) and title != "" do
    with {:ok, text_img} <-
           Image.Text.text(title,
             font: Keyword.get(theme, :font, "Inter"),
             font_size: @title_size,
             text_fill_color: Keyword.get(theme, :foreground, "#ffffff"),
             font_weight: :bold
           ) do
      Image.compose(img, text_img,
        x: @padding,
        y: @title_y,
        mode: "atop"
      )
    end
  end

  defp render_title(img, _title, _theme), do: {:ok, img}

  # ── Description layer (below title, 20px) ─────────────────────────

  defp render_desc(img, desc, theme) when is_binary(desc) and desc != "" do
    with {:ok, text_img} <-
           Image.Text.text(desc,
             font: Keyword.get(theme, :font, "Inter"),
             font_size: @desc_size,
             text_fill_color: Keyword.get(theme, :muted, "#a3a3a3")
           ) do
      Image.compose(img, text_img,
        x: @padding,
        y: @desc_y,
        mode: "atop"
      )
    end
  end

  defp render_desc(img, _desc, _theme), do: {:ok, img}
end
