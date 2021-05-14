defmodule Camp1Web.ChatRoomChannel do
  use Camp1Web, :channel
  alias Camp1.{CampServer, UserServer, PublicChat, Reputation}
  alias Camp1Web.CampView

  def join("chat_room_channel:" <> camp_id, _params, socket) do
    CampServer.start_camp_supervisor(camp_id)
    handle = Reputation.get_handle(socket.assigns[:user_id], camp_id)

    agreement = UserServer.get_user_agreement(socket.assigns[:user_id], camp_id)
    case agreement do
      false ->
        {:error, %{reason: "unauthorized"}}
      true ->
        socket =
          socket
          |> assign(:camp_id, String.to_integer(camp_id))
          |> assign(:handle, handle)
          |> assign(:chat_agreement, agreement)
        {:ok, socket}
    end
  end

  def handle_in("new_message", %{"message" => message}, socket) do
    message = PublicChat.new_message(%{
      camp_id: socket.assigns[:camp_id],
      content: message,
      user_id: socket.assigns[:user_id],
      handle: socket.assigns[:handle]
      })
    html = Phoenix.View.render_to_string(CampView, "users/_chat_messages.html", messages: [message])

    broadcast socket, "new_message", %{html: html}
    {:noreply, socket}
  end

  def handle_in("load_prior_messages", %{"message_count" => message_count}, socket) do
    messages = PublicChat.get_recent_messages(socket.assigns[:camp_id], message_count)
    html = Phoenix.View.render_to_string(CampView, "users/_chat_messages.html", messages: messages)
    {:reply, {:ok, %{html: html}}, socket}
  end

end
