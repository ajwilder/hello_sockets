defmodule Camp1.Private.PrivateChatStash do
  use GenServer
  alias Camp1.Private
  alias Camp1.Private.PrivateChatServer
  alias Camp1.UserServer
  alias Camp1.UserHome.UserChats

  @timeout 24 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000
  @update 60 * 60 * 1000
  @update_users 60 * 1000

  def start(chat, handles, messages) do
    name = :"PrivateChat-#{chat.id}"
    messages = get_initial_messages(chat.id, messages)
    messages = Enum.map(messages, fn message ->
      case Map.get(handles, message.user_id) do
        nil ->
          Map.put(message, :handle, nil)
        handle ->
          Map.put(message, :handle, handle.value)
      end
    end)
    {:ok, process} = GenServer.start(
      __MODULE__,
      %{
        chat_id: chat.id,
        name: chat.name,
        messages: messages,
        handles: handles,
        updated_at: chat.updated_at,
        latest_message: chat.updated_at,
        message_notification_count: 0,
        latest_messagers: []
      },
      name: name,
      hibernate_after: @hibernate
    )
    {:ok, process}
  end

  # HELPER FUNCTION FOR INITIALIZING
  def get_initial_messages(_, []), do: []
  def get_initial_messages(chat_id, nil), do: PrivateChatServer.get_recent_messages_from_db(chat_id)
  def get_initial_messages(_, messages), do: messages


  def init(stash) do
    :timer.send_after(@timeout, :job_timeout)
    :timer.send_after(@update, :update_stash)
    :timer.send_after(@update_users, :update_users)
    {:ok, stash}
  end

  # GET BASIC INFO
  def handle_call(:get_chat_details, _from, stash = %{handles: handles, latest_message: latest_message, name: name, chat_id: chat_id}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, %{
      name: name,
      latest_message: latest_message,
      member_count: length(Map.keys(handles)),
      id: chat_id
      }}, stash}
  end
  def handle_call(:get_handles, _from, stash = %{handles: handles}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, handles}, stash}
  end
  def handle_call(:get_chat_name, _from, stash = %{name: name}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, name}, stash}
  end

  # UPDATE INFO
  def handle_call({:update_chat_name, new_name, user_id}, _from, stash = %{chat_id: chat_id, handles: handles, name: old_name}) do
    :timer.send_after(@timeout, :job_timeout)
    spawn(Private, :update_private_chat, [chat_id, %{name: new_name}])
    handles
    |> Map.keys
    |> Enum.each(fn user_id ->
      spawn(UserServer, :update_private_chat, [user_id, chat_id, %{name: new_name}])
    end)
    handle = Map.get(handles, user_id)
    stash = Map.put(stash, :name, new_name)
    {:reply, {:ok, %{handle: handle.value, old_name: old_name}}, stash}
  end

  # MESSAGES
  def handle_call({:get_messages, count, user_id}, _from, stash = %{messages: messages, handles: handles}) do
    :timer.send_after(@timeout, :job_timeout)
    handle = Map.get(handles, user_id)
    case handle do
      nil ->
        {:reply, :ok, stash}
      handle ->
        {:ok, time_cutoff} = DateTime.from_naive(handle.inserted_at, "Etc/UTC")
        messages = Enum.slice(messages, count, 20)
        messages = filter_messages_by_handle_inserted_at(messages, time_cutoff)
        {:reply, {:ok, messages}, stash}
    end
  end
  def handle_call({:new_message, message = %{user_id: nil}}, _from, stash = %{messages: messages, message_notification_count: message_notification_count}) do
    message = Map.put(message, :handle, "")
    message_notification_count = message_notification_count + 1
    stash =
      stash
      |> Map.put(:messages, [message | messages])
      |> Map.put(:latest_message, message.inserted_at)
      |> Map.put(:message_notification_count, message_notification_count)
    {:reply, {:ok, ""}, stash}
  end
  def handle_call({:new_message, message}, _from, stash = %{messages: messages, handles: handles, latest_messagers: latest_messagers, message_notification_count: message_notification_count}) do
    handle =
      Map.get(handles, message.user_id)
      |> Map.get(:value)
    message = Map.put(message, :handle, handle)
    latest_messagers = [message.user_id | latest_messagers]
    message_notification_count = message_notification_count + 1
    stash =
      stash
      |> Map.put(:messages, [message | messages])
      |> Map.put(:latest_message, message.inserted_at)
      |> Map.put(:latest_messagers, latest_messagers)
      |> Map.put(:message_notification_count, message_notification_count)
    {:reply, {:ok, handle}, stash}
  end
  # USERS
  def handle_call({:new_user, handle}, _from, stash = %{handles: handles, latest_message: latest_message, name: name, chat_id: chat_id}) do
    handles = Map.put(handles, handle.user_id, %{
      user_id: handle.user_id,
      value: handle.value,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      })
    user_ids = Map.keys(handles)
    Private.update_private_chat(chat_id, %{user_ids: user_ids})
    stash =
      stash
      |> Map.put(:handles, handles)
    {:reply, {:ok, %{name: name, latest_message: latest_message, id: chat_id, user_ids: user_ids}}, stash}
  end
  def handle_call({:leave_chat, user_id}, _from, stash = %{handles: handles, name: name, chat_id: chat_id}) do

    spawn(Private, :leave_chat, [chat_id, user_id])
    spawn(UserServer, :leave_chat, [user_id, chat_id])
    handle = Map.get(handles, user_id)
    handles = Map.drop(handles, [user_id])
    user_ids = Map.keys(handles)
    user_ids
    |> Enum.each(fn user_id ->
      spawn(UserServer, :update_private_chat, [user_id, chat_id, %{user_ids: user_ids}])
    end)

    spawn(Private, :update_private_chat, [chat_id, %{user_ids: user_ids}])
    spawn(UserChats, :user_left_chat, [chat_id, handle.value])

    stash =
      stash
      |> Map.put(:handles, handles)

    {:reply, name, stash}
  end


  # INFO METHODS
  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end
  def handle_info(:update_stash, stash = %{messages: messages}) do
    :timer.send_after(@update, :update_stash)
    {:noreply, Map.put(stash, :messages, Enum.slice(messages, 0, 200))}
  end
  def handle_info(:update_users, stash = %{updated_at: updated_at, latest_message: latest_message, handles: handles, chat_id: chat_id, name: name, latest_messagers: latest_messagers, message_notification_count: message_notification_count}) do
    :timer.send_after(@update_users, :update_users)
    if updated_at != latest_message do
      user_ids = Map.keys(handles)
      user_ids
      |> Enum.each(fn user_id ->
        UserServer.chat_updated(user_id, chat_id, name, latest_message, user_ids,  !(Enum.member?(latest_messagers, user_id)), message_notification_count)
      end)
      Private.update_private_chat(chat_id, %{updated_at: latest_message})

      stash =
        stash
        |> Map.put(:updated_at, latest_message)
        |> Map.put(:latest_messagers, [])
        |> Map.put(:message_notification_count, 0)
      {:noreply, stash}
    else
      {:noreply, stash}
    end
  end

  # HELPERS
  def filter_messages_by_handle_inserted_at(messages, cutoff)
  def filter_messages_by_handle_inserted_at([], _), do: []
  def filter_messages_by_handle_inserted_at(messages, cutoff) do
    {:ok, last_message_cutoff} = DateTime.from_naive(List.last(messages).inserted_at, "Etc/UTC")
    case DateTime.compare(cutoff, last_message_cutoff) do
      :eq ->
        messages
      :lt ->
        messages
      :gt ->
        Enum.filter(messages, fn message ->
          {:ok, message_time} = DateTime.from_naive(message.inserted_at, "Etc/UTC")
          case DateTime.compare(cutoff, message_time) do
            :eq ->
              true
            :lt ->
              true
            :gt ->
              false
          end
        end)
    end

  end


end
