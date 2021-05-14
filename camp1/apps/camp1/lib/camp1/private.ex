defmodule Camp1.Private do
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Ecto.Multi
  alias Camp1.Private.{PrivateChat, PrivateHandle, PrivateChatServer, PrivateMessage}

  # DELEGATIONS
  defdelegate init_chat_window(chat_id, user_id), to: PrivateChatServer
  defdelegate get_recent_messages(chat_id, count, user_id), to: PrivateChatServer


  # GETTERS
  def get_private_chat(chat_id) do
    Repo.get(PrivateChat, chat_id)
  end
  def get_private_chat_with_handles(chat_id) do
    Repo.get(PrivateChat, chat_id) |> Repo.preload(:handles)
  end

  # CREATE
  def create_private_chat_handle(attrs) do
    %PrivateHandle{}
    |> PrivateHandle.changeset(attrs)
    |> Repo.insert
  end
  def create_private_chat_with_users(attrs, user_list) do
    Multi.new()
    |> Multi.insert(:private_chat, PrivateChat.changeset(%PrivateChat{}, attrs))
    |> Multi.merge(fn %{private_chat: private_chat} ->
      multi = Enum.reduce(user_list, Multi.new(), fn {id, handle}, multi ->
        Multi.insert(
          multi,
          id,
          PrivateHandle.changeset(
            %PrivateHandle{},
            %{
              user_id: id,
              private_chat_id: private_chat.id,
              value: handle
            }
          )
        )
      end)
      multi = Multi.insert(multi, :first_message,
        PrivateMessage.changeset(%PrivateMessage{}, %{
          private_chat_id: private_chat.id,
          user_id: nil,
          type: :admin,
          content: "Private chat started on #{Date.to_string(DateTime.utc_now)}"
          })
        )
      multi
    end)
    |> Repo.transaction()
  end


  # UPDATE
  def update_private_chat(chat = %PrivateChat{}, attrs) do
    chat
    |> PrivateChat.changeset(attrs)
    |> Repo.update()
  end
  def update_private_chat(chat_id, attrs) do
    %PrivateChat{id: chat_id}
    |> PrivateChat.changeset(attrs)
    |> Repo.update()
  end
  def leave_chat(chat_id, user_id) do
    Repo.get_by(PrivateHandle, %{private_chat_id: chat_id, user_id: user_id}) \
    |> Repo.delete
  end

  # MESSAGES
  def new_message(attrs = %{private_chat_id: chat_id}) do
    {:ok, message} = create_message(attrs)
    PrivateChatServer.new_message(message, chat_id)
  end
  def create_message(attrs) do
    %PrivateMessage{}
    |> PrivateMessage.changeset(attrs)
    |> Repo.insert
  end




end
