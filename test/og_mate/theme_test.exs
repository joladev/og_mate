defmodule OGMate.ThemeTest do
  use ExUnit.Case, async: true

  alias OGMate.Theme

  test "returns struct for valid keyword list" do
    assert %Theme{
             background: "#000000",
             foreground: "#ffffff",
             font: "Inter",
             secondary: "#aaaaaa"
           } =
             Theme.validate!(
               background: "#000000",
               foreground: "#ffffff",
               font: "Inter",
               secondary: "#aaaaaa"
             )
  end

  test "passes through optional keys" do
    assert %Theme{site_name: "myapp.com", logo: "/logo.png", secondary: "#aaaaaa"} =
             Theme.validate!(
               background: "#000000",
               foreground: "#ffffff",
               font: "Inter",
               secondary: "#aaaaaa",
               logo: "/logo.png",
               site_name: "myapp.com"
             )
  end

  test "raises if required key is missing" do
    assert_raise NimbleOptions.ValidationError, ~r/required :foreground option not found/, fn ->
      Theme.validate!(background: "#000000", font: "Inter", secondary: "#aaaaaa")
    end
  end

  test "raises on unknown key" do
    assert_raise NimbleOptions.ValidationError, ~r/unknown options \[:backgrund\]/, fn ->
      Theme.validate!(
        backgrund: "#000000",
        foreground: "#ffffff  ",
        font: "Inter",
        secondary: "#aaaaaa"
      )
    end
  end
end
