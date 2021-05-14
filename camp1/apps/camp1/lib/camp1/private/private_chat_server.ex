defmodule Camp1.Private.PrivateChatServer do
  alias Camp1.Private.{PrivateChat, PrivateHandle, PrivateChatStash, PrivateMessage}
  alias Camp1.Private
  alias Camp1Web.UserView
  alias Camp1.{Repo}
  import Ecto.Query, warn: false


  # MESSAGES
  def new_message(message, chat_id) do
    process = get_chat_process(chat_id)
    message = %{
      content: message.content,
      inserted_at: message.inserted_at,
      user_id: message.user_id,
      type: message.type
    }
    {:ok, handle} = GenServer.call(process, {:new_message, message})
    Map.put(message, :handle, handle)
  end
  def get_recent_messages(chat_id, count, user_id) do
    process = get_chat_process(chat_id)
    {:ok, messages} = GenServer.call(process, {:get_messages, count, user_id})
    messages
  end



  # INIT
  def init_chat_window(chat_id, user_id) do
    %{
      id: chat_id,
      handles: get_chat_handles(chat_id),
      name: get_chat_name(chat_id),
      messages: get_recent_messages(chat_id, 0, user_id)
    }
  end
  def init_chat_server(data = %{private_chat: private_chat, first_message: first_message}) do
    handles =
      data
      |> Map.drop([:private_chat, :first_message])
      |> Enum.reduce(%{}, fn handle, map ->
        Map.put(map, elem(handle,0), Map.drop(elem(handle,1),[:user, :private_chat, :private_chat_id, :id]))
      end)
    {:ok, process} = PrivateChatStash.start(private_chat, handles, [first_message])
    process
  end
  def init_chat_server(chat_id) do
    chat = get_chat_data_from_db(chat_id)
    handles = get_handles_from_db(chat_id)
    messages = get_recent_messages_from_db(chat_id)

    {:ok, process} = PrivateChatStash.start(chat, handles, messages)
    process
  end


  # INFO
  def get_chat_details(chat_id) do
    process = get_chat_process(chat_id)
    {:ok, details} = GenServer.call(process, :get_chat_details)
    details
  end
  def get_chat_name(chat_id) do
    process = get_chat_process(chat_id)
    {:ok, name} = GenServer.call(process, :get_chat_name)
    name
  end
  def get_chat_handles(chat_id) do
    process = get_chat_process(chat_id)
    {:ok, handles} = GenServer.call(process, :get_handles)
    handles
  end


  # USERS
  def add_user_to_chat(attrs = %{private_chat_id: chat_id}) do
    process = get_chat_process(chat_id)
    {:ok, private_chat} = GenServer.call(process, {:new_user, attrs})
    private_chat
  end



  # UPDATE
  def update_chat_name(chat_id, new_name, user_id) do
    process = get_chat_process(chat_id)
    {:ok, %{handle: handle, old_name: _old_name}} = GenServer.call(process, {:update_chat_name, new_name, user_id})

    message = Private.new_message(%{
      private_chat_id: chat_id,
      content: "#{handle} changed the name of this chat to \"#{new_name}\"",
      user_id: user_id,
      type: :admin
      })
    html = Phoenix.View.render_to_string(UserView, "chat/_chat_messages.html", messages: [message], id: chat_id, init: false)
    Camp1Web.Endpoint.broadcast!("private_chat_channel:#{chat_id}", "new_message", %{html: html, chat: chat_id, new_name: new_name})
  end
  def leave_chat(chat_id, user_id) do
    process = get_chat_process(chat_id)
    GenServer.call(process, {:leave_chat, user_id})
  end


  # DB METHODS
  def get_chat_data_from_db(chat_id) do
    q = from chat in PrivateChat,
      where: chat.id == ^chat_id,
      select: %{name: chat.name, id: chat.id, updated_at: chat.updated_at}
    Repo.all(q)
    |> List.first
  end
  def get_handles_from_db(chat_id) do
    q = from handle in PrivateHandle,
      where: handle.private_chat_id == ^chat_id,
      select: %{
        value: handle.value,
        user_id: handle.user_id,
        inserted_at: handle.inserted_at,
        updated_at: handle.updated_at
      }
    Repo.all(q)
    |> Enum.reduce(%{}, fn handle, map ->
      Map.put(map, handle.user_id, handle)
    end)
  end
  def get_recent_messages_from_db(chat_id) do
    query_recent_messages(chat_id)
    |> Repo.all
  end
  defp query_recent_messages(chat_id) do
    from message in PrivateMessage,
      where: message.private_chat_id == ^chat_id,
      limit: 200,
      order_by: {:desc, message.inserted_at},
      select: %{
        content: message.content,
        inserted_at: message.inserted_at,
        user_id: message.user_id,
        type: message.type
      }
  end


  # HELPERS
  defp get_chat_process(chat_id) do
    process = Process.whereis(:"PrivateChat-#{chat_id}")
    case process do
      nil ->
        init_chat_server(chat_id)
      process ->
        process
    end
  end

end
