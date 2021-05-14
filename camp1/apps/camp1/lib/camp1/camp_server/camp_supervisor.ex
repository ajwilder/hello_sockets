defmodule Camp1.CampServer.CampSupervisor do
  alias Camp1.CampServer.{BoardStash, ImageBoard, CampCoreStash, ChatRoom, CampCompareStash, AudioRoom}
  alias Camp1.Manifesto.ManifestoStash

  def start_server(camp_id) do
    name = :"CampServerSupervisor-#{camp_id}"

    children = [
      %{
        id: :CampBoardStash,
        start: {BoardStash, :start_link, [%{name: :"CampBoardStash-#{camp_id}", camp_id: camp_id}]}
      },
      %{
        id: :CampCoreStash,
        start: {CampCoreStash, :start_link, [%{name: :"CampCoreStash-#{camp_id}", camp_id: camp_id}]}
      },
      %{
        id: :CampCompareStash,
        start: {CampCompareStash, :start_link, [%{name: :"CampCompareStash-#{camp_id}", camp_id: camp_id}]}
      },
      %{
        id: :CampImageBoard,
        start: {ImageBoard, :start_link, [%{name: :"CampImageBoard-#{camp_id}", camp_id: camp_id}]}
      },
      %{
        id: :CampChatRoom,
        start: {ChatRoom, :start_link, [%{name: :"CampChatRoom-#{camp_id}", camp_id: camp_id}]}
      },
      %{
        id: :CampAudioRoom,
        start: {AudioRoom, :start_link, [%{name: :"CampAudioRoom-#{camp_id}", camp_id: camp_id}]}
      },
      %{
        id: :CampManifestoStash,
        start: {ManifestoStash, :start_link, [%{name: :"CampManifestoStash-#{camp_id}", camp_id: camp_id}]}
      }
    ]

    opts = [strategy: :one_for_one, name: name]
    Supervisor.start_link(children, opts)
  end

end
