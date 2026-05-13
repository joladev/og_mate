defmodule OgMateTest do
  use ExUnit.Case
  doctest OgMate

  test "greets the world" do
    assert OgMate.hello() == :world
  end
end
