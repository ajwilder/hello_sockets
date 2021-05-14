defmodule Camp1.CampServer.AudioRoom do
  use GenServer
  @timeout 48 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000


  def start_link(%{name: name, camp_id: camp_id}) do
    {:ok, file} = File.open("audio_feed", [:write])
    GenServer.start_link(
      __MODULE__,
      %{
        file: file,
        camp_id: camp_id,
        data: []
      },
      name: name, hibernate_after: @hibernate)
  end

  def init(stash) do
    :timer.send_after(@timeout, :job_timeout)
    {:ok, stash}
  end

  def handle_call(:data_length, _from, stash = %{data: data}) do
    {:reply, {length(data), :erlang.external_size(data)}, stash}
  end

  def handle_call({:get_data, num}, _from, stash = %{data: data}) do
    {:reply, Enum.slice(Enum.reverse(data), num), stash}
  end

  def handle_cast({:incoming_stream, message}, stash = %{data: data, file: file}) do
    data =[message | data]
    IO.binwrite(file, message)
    IO.binwrite(file, " ")
    IO.puts "receiving data"
    {:noreply, Map.put(stash, :data, data)}
  end

  def handle_cast(:broadcast_data, stash = %{data: data}) do
    broadcast_data(Enum.reverse(data))
    {:noreply, stash}
  end


  def handle_cast(:clear_data, stash) do
    {:noreply, Map.put(stash, :data, [])}
  end


  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end

  def broadcast_data([]), do: :ok
  def broadcast_data([head | tail]) do
    Phoenix.PubSub.broadcast(Camp1.PubSub, "audioBroadcast1", {:send_audio, head})
    broadcast_data(tail)
  end

  def broadcast_to_audio_socket(data) do
    if data != "\n" do
      Phoenix.PubSub.broadcast(Camp1.PubSub, "audioBroadcast1", {:send_audio, data})
    end
  end
end
