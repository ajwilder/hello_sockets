defmodule Camp1Web.PrivateChatChannel do
  use Camp1Web, :channel
  alias Camp1.{Private, UserServer}
  alias Camp1Web.UserView

  def join("private_chat_channel:" <> chat_id, _params, socket) do
    chat_id = String.to_integer(chat_id)
    socket =
      socket
      |> assign(:chat_id, chat_id)
    UserServer.put_active_chat(socket.assigns[:user_id], %{type: :private, id: chat_id})
    {:ok, socket}
  end

  def handle_in("new_message", %{"message" => message, "chat" => chat}, socket) do
    chat_id = socket.assigns[:chat_id]
    case chat_id == String.to_integer(chat) do
      false ->
        {:error, :unauthorized}
      true ->
        message = Private.new_message(%{
          private_chat_id: chat_id,
          content: message,
          user_id: socket.assigns[:user_id],
          })

        html = Phoenix.View.render_to_string(UserView, "chat/_chat_messages.html", messages: [message], id: chat_id, init: false)

        broadcast socket, "new_message", %{html: html}
        {:noreply, socket}
    end
  end

  def handle_in("load_prior_messages", %{"chat" => chat_id, "message_count" => message_count}, socket) do
    messages = Private.get_recent_messages(chat_id, message_count, socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "chat/_chat_messages.html", messages: messages, id: chat_id, init: false)
    {:reply, {:ok, %{html: html}}, socket}
  end
end
