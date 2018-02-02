defmodule ExLoaderTest do
  use ExUnit.Case
  doctest ExLoader

  test "greets the world" do
    assert ExLoader.hello() == :world
  end
end
