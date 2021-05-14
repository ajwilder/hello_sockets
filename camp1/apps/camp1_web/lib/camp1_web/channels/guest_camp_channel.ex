defmodule Camp1Web.GuestCampChannel do
  use Camp1Web, :channel
  alias Camp1.CampHome
  alias Camp1.CampServer


  def join("guest_camp_channel:" <> id, _params, socket) do
    start_camp_servers(id)
    socket =
      socket
      |> assign(:camp_id, id)
    {:ok, socket}
  end

  def handle_in("get_message_board", _params, socket) do
    id = socket.assigns[:camp_id]
    message_board = CampServer.get_message_board(id)
    {:reply, {:ok, message_board}, socket}

  end

  defp start_camp_servers(id) do
    CampServer.start_camp_supervisor(id)
  end

end
