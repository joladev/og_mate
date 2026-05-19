defmodule OGMate.RendererTest do
  use ExUnit.Case, async: true

  test "renders PNG with full theme" do
    theme = %OGMate.Theme{
      background: "#000000",
      foreground: "#ffffff",
      font: "Inter",
      secondary: "#aaaaaa",
      logo: nil,
      site_name: "example.com"
    }

    assert {:ok, <<0x89, "PNG", _::binary>>} =
             OGMate.Renderer.render("Title", "Description", theme)
  end

  test "renders PNG with no logo and no site_name" do
    theme = %OGMate.Theme{
      background: "#000000",
      foreground: "#ffffff",
      font: "Inter",
      secondary: "#aaaaaa",
      logo: nil,
      site_name: nil
    }

    assert {:ok, <<0x89, "PNG", _::binary>>} =
             OGMate.Renderer.render("Title", "Description", theme)
  end
end
