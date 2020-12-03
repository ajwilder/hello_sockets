defmodule Ticker do

  @interval 2000
  @name :ticker

  def start do
    pid = spawn(__MODULE__, :generator, [[]])
    :global.register_name(@name, pid)
  end

  def register(client_pid) do
    send :global.whereis_name(@name), { :register, client_pid }
  end

  def generator([]) do
    receive do
      { :register, pid } ->
        IO.puts "registering #{inspect pid} #{Time.utc_now.second}:#{Time.utc_now.microsecond |> elem(0) |> div(1000) |> Integer.to_string |> String.pad_leading(3,"0")}"
        generator([pid])
    after
      @interval ->
        IO.puts "tick #{Time.utc_now.second}:#{Time.utc_now.microsecond |> elem(0) |> div(1000) |> Integer.to_string |> String.pad_leading(3,"0")}"
        generator([])
    end
  end
  def generator(clients) do
    [ head_client | tail_clients] = clients
    receive do
      { :register, pid } ->
        IO.puts "registering #{inspect pid} #{Time.utc_now.second}:#{Time.utc_now.microsecond |> elem(0) |> div(1000) |> Integer.to_string |> String.pad_leading(3,"0")}"
        generator([pid | clients])
    after
      @interval ->
        IO.puts "tick #{Time.utc_now.second}:#{Time.utc_now.microsecond |> elem(0) |> div(1000) |> Integer.to_string |> String.pad_leading(3,"0")}"
        send head_client, {:tick}
        generator(tail_clients ++ [head_client])
    end
  end
end

defmodule Client do
  def start do
    pid = spawn(__MODULE__, :receiver, [])
    Ticker.register(pid)
  end

  def receiver do
    receive do
      {:tick} -> IO.puts "tock in client #{Time.utc_now.second}:#{Time.utc_now.microsecond |> elem(0) |> div(1000) |> Integer.to_string |> String.pad_leading(3,"0")} - #{inspect self()}"
      receiver()
    end
  end
end
