defmodule DevMode.FakeRenderer do
  def render(title, _desc), do: {:ok, "fake:" <> title}
end

defmodule DevMode.FakeContent do
  def content_for("home"), do: {"Home", "Welcome"}
  def content_for("about"), do: {"About", "About me"}
  def content_for(_), do: :error
end

defmodule DevMode do
  use OGMate,
    all_keys: ["home", "about"],
    content_for: DevMode.FakeContent,
    renderer: DevMode.FakeRenderer,
    default: {"Default", "Default desc"},
    dev_mode: true
end
