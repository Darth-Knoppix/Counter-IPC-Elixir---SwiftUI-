defmodule CounterIpcTest do
  use ExUnit.Case
  doctest CounterIpc

  test "greets the world" do
    assert CounterIpc.hello() == :world
  end
end
