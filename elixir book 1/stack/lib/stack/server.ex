defmodule Stack.Server do
  use GenServer

  @me __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @me )
  end

  def pop() do
    GenServer.call(@me, :pop)
  end

  def push(element) when is_integer(element) and element < 10 do
    System.halt("ints must be greater than 10")
    GenServer.cast(@me, {:push, element})
  end

  def push(element) do
    GenServer.cast(@me, {:push, element})
  end

  def init(nil) do
    { :ok, Stack.Stash.get }
  end

  def handle_call(:pop, _from, [head | tail]) do
    { :reply, head, tail }
  end

  def handle_cast({:push, element}, list) do
    {:noreply, [element|list]}
  end

  def terminate(_reason, list) do
    Stack.Stash.update(list)
  end


end
