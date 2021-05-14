defmodule Camp1Web.UserRTChannel do
  use Camp1Web, :channel
  alias Camp1.{UserHome, UserServer}
  alias Camp1Web.{UserView}
  alias Camp1.Private

  def join("user_rt_channel:" <> user_id, _params, socket) do
    user_id = String.to_integer user_id
    case user_id == socket.assigns[:user_id] do
      true ->
        chats = UserHome.get_chats_by_recent(user_id)
        missed_messages = UserHome.get_missed_messages(user_id)
        active_chats = UserServer.get_active_chats(user_id)
        html = Phoenix.View.render_to_string(UserView, "widget/_chat_widget.html", %{chats: chats, missed_messages: missed_messages})
        {:ok, %{html: html, active_chats: active_chats}, socket}
      false ->
        {:error, :unauthorized}
    end
  end

  def handle_in("chat_invite_yes", %{"invite" => invite_id}, socket) do
    invite_id = String.to_integer(invite_id)
    invitation = UserHome.get_pending_chat_invitation(socket.assigns[:user_id], invite_id)
    invitation = UserHome.accept_chat_invitation(invitation)
    html = Phoenix.View.render_to_string(UserView, "chat/_chat_received_invitations.html", %{invitations: [invitation]})
    {:reply, {:ok, %{html: html}}, socket}
  end

  def handle_in("chat_invite_no", %{"invite" => invite_id}, socket) do
    invite_id = String.to_integer(invite_id)
    invitation = UserHome.get_pending_chat_invitation(socket.assigns[:user_id], invite_id)
    invitation = UserHome.decline_chat_invitatation(invitation)
    html = Phoenix.View.render_to_string(UserView, "chat/_chat_received_invitations.html", %{invitations: [invitation]})
    {:reply, {:ok, %{html: html}}, socket}
  end

  def handle_in("open_chat", %{"chat" => chat_id}, socket) do
    chat_id = String.to_integer(chat_id)
    UserServer.chat_opened(socket.assigns[:user_id], chat_id)
    data = Private.init_chat_window(chat_id, socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "widget/_chat_window.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end

  def handle_in("notify_chat", %{"chat" => chat_id}, socket) do
    chat_id = String.to_integer(chat_id)
    UserServer.chat_opened(socket.assigns[:user_id], chat_id)
    {:reply, :ok, socket}
  end

  def handle_in("chat_window_closed", _params, socket) do
    UserServer.chat_window_closed(socket.assigns[:user_id])
    {:reply, :ok, socket}
  end
end
