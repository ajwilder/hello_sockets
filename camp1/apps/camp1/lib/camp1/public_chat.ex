defmodule Camp1.PublicChat do
  alias Camp1.PublicChat.PublicMessage
  alias Camp1.{Repo, CampServer}
  import Ecto.Query, warn: false
  alias Camp1.Reputation.Handle

  def new_message(attrs = %{camp_id: camp_id}) do
    {:ok, message} = create_message(attrs)

    attrs =
      attrs
      |> Map.put(:inserted_at, message.inserted_at)
      |> Map.drop([:camp_id])
    process = get_chat_process(camp_id)
    GenServer.cast(process, {:new_message, attrs})
    attrs
  end

  def create_message(attrs) do
    %PublicMessage{}
    |> PublicMessage.changeset(attrs)
    |> Repo.insert
  end

  def get_recent_messages(camp_id, count) do
    process = get_chat_process(camp_id)
    {:ok, messages} = GenServer.call(process, {:get_messages, count})
    messages
  end

  def get_recent_messages_from_db(camp_id) do
    query_recent_messages(camp_id)
    |> Repo.all
  end

  defp query_recent_messages(camp_id) do
    from message in PublicMessage,
      where: message.camp_id == ^camp_id,
      join: handle in Handle,
      where: handle.camp_id == ^camp_id,
      where: handle.user_id == message.user_id,
      limit: 500,
      order_by: {:desc, message.inserted_at},
      select: %{
        content: message.content,
        handle: handle.value,
        inserted_at: message.inserted_at,
        user_id: message.user_id
      }
  end

  defp get_chat_process(camp_id) do
    process = Process.whereis(:"CampChatRoom-#{camp_id}")
    case process do
      nil ->
        CampServer.start_camp_supervisor(camp_id)
        get_chat_process(camp_id)
      process ->
        process
    end
  end

end
