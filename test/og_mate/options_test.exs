defmodule OGMate.OptionsTest do
  use ExUnit.Case, async: true

  alias OGMate.Options

  defmodule FakeContent do
    def content_for(_), do: {"t", "d"}
  end

  defmodule FakeRenderer do
    def render(_, _), do: {:ok, "x"}
  end

  @valid_base [
    all_keys: ["a"],
    content_for: FakeContent,
    default: {"D", "d"}
  ]

  @valid_theme [
    background: "#000",
    foreground: "#fff",
    font: "Inter",
    secondary: "#aaa"
  ]

  test "theme path returns struct with theme set, renderer nil" do
    opts = @valid_base ++ [theme: @valid_theme]
    assert %Options{theme: %OGMate.Theme{}, renderer: nil} = Options.validate!(opts)
  end

  test "renderer path returns struct with renderer set, theme nil" do
    opts = @valid_base ++ [renderer: FakeRenderer]
    assert %Options{theme: nil, renderer: FakeRenderer} = Options.validate!(opts)
  end

  test "raises when both theme and renderer are passed" do
    opts = @valid_base ++ [theme: @valid_theme, renderer: FakeRenderer]

    assert_raise ArgumentError, ~r/either :theme or :renderer/, fn ->
      Options.validate!(opts)
    end
  end

  test "raises when neither theme nor renderer is passed" do
    assert_raise ArgumentError, ~r/must pass :theme or :renderer/, fn ->
      Options.validate!(@valid_base)
    end
  end
end
