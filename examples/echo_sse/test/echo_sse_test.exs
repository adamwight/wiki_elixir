defmodule EchoSseTest do
  use ExUnit.Case
  doctest EchoSse

  test "greets the world" do
    assert EchoSse.hello() == :world
  end
end
