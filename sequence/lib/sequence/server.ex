defmodule Sequence.Server do
  use GenServer


  # EXTERNAL API
  def start_link(current_number) do
    GenServer.start_link(__MODULE__, current_number, name: __MODULE__)
  end

  def next_number do
    GenServer.call __MODULE__, :next_number
  end

  def increment_number(delta) do
    GenServer.cast __MODULE__, { :increment_number, delta }
  end


  # GENSERVER IMPLEMENTATION
  def init(initial_number) do
    { :ok, initial_number }
  end

  def handle_call(:next_number, _from, current_number) do
    { :reply, current_number, current_number + 1 }
  end

  def handle_call({:set_number, new_number}, _from, _current_number) do
    { :reply, new_number, new_number}
  end

  def handle_call(:butts , _from, current_number) do
    { :reply, :nobutts, current_number}
  end

  def handle_call(:whocalls , from, current_number) do
    { :reply, from, current_number}
  end

  # def handle_call({:factors, number}, _,_ ) do
  #   {:reply, { :factors_of, number, factors(number)}, [] }
  # end

  def handle_cast({:increment_number, delta}, current_number) do
    { :noreply, current_number + delta}
  end

  def format_status(_reason, [_pdict, state]) do
    [data: [{'State', "My current state is '#{inspect state}', and I'm happy"}]]
  end



end
