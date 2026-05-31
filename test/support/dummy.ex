defmodule Dummy.FakeRenderer do
  @moduledoc false
  def render(title, _desc), do: {:ok, "fake:" <> title}
end

defmodule Dummy.FakeContent do
  @moduledoc false
  def content_for("home"), do: {"Home", "Welcome"}
  def content_for("about"), do: {"About", "About me"}
  def content_for(_), do: :error
end

defmodule Dummy do
  @moduledoc false
  use OGMate,
    all_keys: ["home", "about"],
    content_for: Dummy.FakeContent,
    renderer: Dummy.FakeRenderer,
    default: {"Default", "Default desc"}
end
