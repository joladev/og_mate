defmodule OGMateTest do
  use ExUnit.Case, async: true

  alias OGMateTest.Example

  defmodule FakeRenderer do
    def render(title, _desc), do: {:ok, "fake:" <> title}
  end

  defmodule FakeContent do
    def content_for("home"), do: {"Home", "Welcome"}
    def content_for("about"), do: {"About", "About me"}
    def content_for(_), do: :error
  end

  setup do
    :code.purge(Example)
    :code.delete(Example)
    :ok
  end

  test "bakes images for all keys using custom renderer" do
    defmodule Example do
      use OGMate,
        all_keys: ["home", "about"],
        content_for: OGMateTest.FakeContent,
        renderer: OGMateTest.FakeRenderer,
        default: {"Default", "Default desc"}
    end

    assert {:ok, "fake:Home"} = Example.image_for("home")
    assert {:ok, "fake:About"} = Example.image_for("about")
    assert {:ok, "fake:Default"} = Example.image_for("unknown_key")
  end

  test "dev_mode renders at runtime" do
    defmodule Example do
      use OGMate,
        all_keys: ["home", "about"],
        content_for: OGMateTest.FakeContent,
        renderer: OGMateTest.FakeRenderer,
        default: {"Default", "Default desc"},
        dev_mode: true
    end

    assert {:ok, "fake:Home"} = Example.image_for("home")
    assert {:ok, "fake:About"} = Example.image_for("about")
    assert {:ok, "fake:Default"} = Example.image_for("unknown")
  end

  test "default renderer produces PNG bytes from theme" do
    defmodule Example do
      use OGMate,
        all_keys: ["home"],
        content_for: OGMateTest.FakeContent,
        theme: [
          background: "#000000",
          foreground: "#ffffff",
          font: "Inter",
          secondary: "#aaaaaa"
        ],
        default: {"Default", "Default desc"}
    end

    assert {:ok, bytes} = Example.image_for("home")
    assert <<0x89, "PNG", _rest::binary>> = bytes
  end
end
