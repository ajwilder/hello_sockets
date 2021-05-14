defmodule Camp1.CampServer.ChatRoom do
  use GenServer
  alias Camp1.PublicChat
  @timeout 48 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000
  @update 60 * 60 * 1000

  # TODO: periodicly clean out old messages

  def start_link(%{name: name, camp_id: camp_id}) do
    messages = PublicChat.get_recent_messages_from_db(camp_id)
    GenServer.start_link(
      __MODULE__,
      %{
        camp_id: camp_id,
        messages: messages
      },
      name: name, hibernate_after: @hibernate)
  end

  def init(stash) do
    :timer.send_after(@timeout, :job_timeout)
    :timer.send_after(@update, :update_stash)
    {:ok, stash}
  end

  def handle_call({:get_messages, count}, _from, stash = %{messages: messages}) do
    :timer.send_after(@timeout, :job_timeout)
    messages = Enum.slice(messages, count, 20)
    {:reply, {:ok, messages}, stash}
  end

  def handle_cast({:new_message, message}, stash = %{messages: messages}) do

    {:noreply, Map.put(stash, :messages, [message | messages])}
  end

  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end

  def handle_info(:update_stash, stash = %{messages: messages}) do
    :timer.send_after(@update, :update_stash)
    {:noreply, Map.put(stash, :messages, Enum.slice(messages, 0, 200))}
  end

end
