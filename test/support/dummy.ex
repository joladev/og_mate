defmodule Dummy.FakeRenderer do
  def render(title, _desc), do: {:ok, "fake:" <> title}
end

defmodule Dummy.FakeContent do
  def content_for("home"), do: {"Home", "Welcome"}
  def content_for("about"), do: {"About", "About me"}
  def content_for(_), do: :error
end

defmodule Dummy do
  use OGMate,
    all_keys: ["home", "about"],
    content_for: Dummy.FakeContent,
    renderer: Dummy.FakeRenderer,
    default: {"Default", "Default desc"}
end
