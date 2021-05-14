defmodule ScratchPad do
  def sum_up_list_values(list, results \\ %{total: 0})
  def sum_up_list_values([], results), do: results
  def sum_up_list_values([value|tail], results) do
    current_count = Map.get results, value
    current_total = Map.get results, :total
    case current_count do
      nil ->
        results = Map.put(results, value, 1)
        results = Map.put(results, :total, current_total + 1)
        sum_up_list_values(tail, results)
      _ ->
        results = Map.put(results, value, current_count + 1)
        results = Map.put(results, :total, current_total + 1)
        sum_up_list_values(tail, results)
    end
  end


end


tribes = Public.list_tribes |> Repo.preload(:subject)

Enum.each(tribes, fn tribe ->
  subject = tribe.subject
  Public.update_tribe(tribe, %{
    top_subject_id: subject.parent_id
    })

end)

Repo.all(PrivateChat) \
|> Repo.preload(:handles) \
|> Enum.each(fn chat ->
  user_ids =
    chat.handles \
    |> Enum.map(fn handle -> handle.user_id end)

  Private.update_private_chat(chat, %{user_ids: user_ids})

end)


Repo.delete_all PrivateHandle
Repo.delete_all ChatInvitation
Repo.delete_all PrivateMessage
Repo.delete_all PrivateChat

c =
b \
|> Map.keys \
|> Enum.reduce(%{}, fn key, map ->
  data = b[key]
  data = %{
    "a" => data["agreements"],
    "d" => data["disagreements"],
    "m" => data["member_overlap"]
  }
  Map.put(map, key, data)

end)

alias Camp1.Audio.SimplePipeline
path = "/Users/alanwilder/Downloads/Cheers.mp3"
{:ok, pid} = SimplePipeline.start_link(path)
SimplePipeline.play(pid)


file = File.stream!("audio_feed.opus") |>  IO.stream(:line)
File.stream!(file, [], 2048) |> Camp1.CampServer.AudioRoom.broadcast_to_audio_socket
File.stream!(file) |> IO.puts


File.stream!("audio_feed.opus", [], 4096) |> Stream.map(fn x -> Camp1.CampServer.AudioRoom.broadcast_to_audio_socket(x) end) |> Stream.run

File.stream!("audio_feed2") |> Stream.map(fn x -> Camp1.CampServer.AudioRoom.broadcast_to_audio_socket(x) end) |> Stream.run

File.stream!("audio_feed", [], 4096) |> Stream.map(fn x -> Camp1.CampServer.AudioRoom.broadcast_to_audio_socket(x) end) |> Stream.run


File.stream!("audio_feed") |> Stream.map(fn x -> Camp1.CampServer.AudioRoom.broadcast_to_audio_socket(String.trim(x, "\n")) end) |> Stream.run






File.stream!("audio_feed3") |> Stream.map(fn x -> Camp1.CampServer.AudioRoom.broadcast_to_audio_socket(x) end) |> Stream.run
File.stream!("audio_feed") |> Stream.map(fn x -> Camp1.CampServer.AudioRoom.broadcast_to_audio_socket(x) end) |> Stream.run


File.stream!("audio_feed4") |> Stream.map(fn x -> Camp1.CampServer.AudioRoom.broadcast_to_audio_socket(String.trim(x, "blank")) end) |> Stream.run




{:ok, pid} = Camp1.Audio.OpusDecodePipeline.start_link("audio_feed")
Camp1.Audio.OpusDecodePipeline.play pid
