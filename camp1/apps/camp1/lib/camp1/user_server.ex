defmodule Camp1.UserServer do
  alias Camp1.UserServer.{UserStash, UserCompare}
  alias Camp1.Accounts.UserData
  alias Camp1Web.UserView
  alias Camp1.Invitations.{ChatInvitation}
  import Ecto.Query, warn: false
  alias Camp1.{Repo, UserHome, Manifesto}
  alias Camp1.Reactions.{Rating, Vote}
  alias Camp1.Board.Comment

  # MISC
  def get_user_home_explore(user_id, page) do
    process = get_user_server_process(user_id)
    {:ok, user_explore_camps} = GenServer.call(process, {:get_user_explore_camps, page})
    case user_explore_camps do
      nil ->
        {ids, camps} = UserHome.create_user_explore(user_id)
        put_user_explore_camps(process, ids, camps)
        ids
        |> Enum.slice(((page * 20)), 20)
        |> Enum.map(&(camps[&1]))
      user_explore_camps ->
        user_explore_camps
    end
  end
  def get_user_handle(user_id) do
    process = get_user_server_process(user_id)
    {:ok, handle} = GenServer.call(process, :get_user_handle)
    case handle do
      nil ->
        handle = UserHome.get_default_user_handle_from_database(user_id)
        put_user_handle(process, handle)
        handle
      handle ->
        handle
    end
  end

  # CHAT INVITATIONS
  def get_pending_chat_invitations(user_id) do
    process = get_user_server_process(user_id)
    {:ok, invitations} = GenServer.call(process, :get_pending_chat_invitations)
    invitations
  end
  def get_pending_chat_invitation(user_id, invite_id) do
    process = get_user_server_process(user_id)
    {:ok, invitation} =
      GenServer.call(process, {:get_pending_chat_invitation, invite_id})
    invitation
  end
  def new_chat_invitation(_invitation = %ChatInvitation{user_handle: user_handle, inviter_handle: inviter_handle, user_id: user_id, inviter_id: inviter_id, id: id, private_chat_id: private_chat_id}) do
    put_pending_invitation_to_stash(user_id, %{
      private_chat_id: private_chat_id,
      id: id,
      inviter_handle: inviter_handle,
      inviter_id: inviter_id,
      user_handle: user_handle,
      user_id: user_id,
      status: :pending,
      type: :received,
      source: nil
      })
    put_pending_invitation_to_stash(inviter_id, %{
      private_chat_id: private_chat_id,
      id: id,
      inviter_handle: inviter_handle,
      inviter_id: inviter_id,
      user_handle: user_handle,
      user_id: user_id,
      status: :pending,
      type: :sent,
      source: nil
      })
  end
  def put_pending_invitation_to_stash(user_id, invitation) do
    process = get_user_server_process(user_id)
    GenServer.cast(process, {:new_pending_chat_invitation, invitation})
  end
  def update_chat_invitation(user_id, invitation) do
    process = get_user_server_process(user_id)
    GenServer.cast(process, {:update_chat_invitation, invitation})
  end


  # CHATS
  def authenticate_chat_details(user_id, chat_id) do
    process = get_user_server_process(user_id)
    GenServer.call(process, {:is_authenticated?, chat_id})
  end
  def get_chats_by_recent(user_id) do
    process = get_user_server_process(user_id)
    {:ok, chats} = GenServer.call(process, :get_recent_chats)
    chats
  end
  def get_chats_by_created(user_id) do
    process = get_user_server_process(user_id)
    {:ok, chats} = GenServer.call(process, :get_chats_by_joined)
    chats
  end
  def get_chats_by_alpha(user_id) do
    process = get_user_server_process(user_id)
    {:ok, chats} = GenServer.call(process, :get_chats_by_alpha)
    chats
  end
  def get_active_chats(user_id) do
    process = get_user_server_process(user_id)
    {:ok, chats} = GenServer.call(process, :get_active_chats)
    chats
  end
  def get_chats_by_search(user_id, query) do
    process = get_user_server_process(user_id)
    {:ok, chats} = GenServer.call(process, {:get_chats_by_search, query})
    chats
  end
  def get_contact_chats(user_id, contact_id) do
    process = get_user_server_process(user_id)
    {:ok, chats} = GenServer.call(process, {:get_contact_chats, contact_id})
    chats
  end
  def get_contact_two_person_chat(user_id, contact_id) do
    process = get_user_server_process(user_id)
    GenServer.call(process, {:get_contact_two_person_chat, contact_id})
  end
  def get_missed_messages(user_id) do
    process = get_user_server_process(user_id)
    {:ok, missed_messages} = GenServer.call(process, :get_missed_messages)
    missed_messages
  end
  def chat_updated(user_id, chat_id, name, latest_message, user_ids, send_update?, message_count) do
    process = Process.whereis(:"UserStash-#{user_id}")
    case process do
      nil ->
        spawn(UserData, :add_missed_messages, [user_id, [{chat_id, message_count}]])
      process ->
        GenServer.cast(process, {:chat_updated, chat_id, latest_message, user_ids, message_count, send_update?})
        if send_update? do
          html = Phoenix.View.render_to_string(UserView, "popups/_popup_chat_updated.html", %{chat_id: chat_id, name: name})
          Camp1Web.Endpoint.broadcast!("user_rt_channel:#{user_id}", "chat_update", %{
            name: name, chat: chat_id, popup_html: html, dom_id: "chatUpdatePopup#{chat_id}", message_count: message_count
            })
        end
    end
  end
  def put_active_chat(user_id, chat_map) do
    process = get_user_server_process(user_id)
    GenServer.cast(process, {:put_active_chat, chat_map})
  end
  def chat_opened(user_id, chat_id) do
    process = get_user_server_process(user_id)
    GenServer.cast(process, {:chat_opened, chat_id})
  end
  def update_private_chat(user_id, chat_id, attrs) do
    process = Process.whereis(:"UserStash-#{user_id}")
    case process do
      nil ->
        :ok
      process ->
        GenServer.cast(process, {:update_private_chat, chat_id, attrs})
    end
  end
  def leave_chat(user_id, chat_id) do
    process = Process.whereis(:"UserStash-#{user_id}")
    case process do
      nil ->
        :ok
      process ->
        GenServer.cast(process, {:leave_chat, chat_id})
    end
  end
  def chat_window_closed(user_id) do
    process = get_user_server_process(user_id)
    GenServer.cast(process, :chat_window_closed)
  end

  # CAMP DATA
  def get_vote_data(user_id, camp_id) do
    process = get_user_server_process(user_id)
    {:ok, vote_data} = GenServer.call(process, {:get_user_vote_data, camp_id})
    case vote_data do
      nil ->
        vote_data = get_user_vote_data_from_database(user_id, camp_id)
        put_user_vote_data(process, {camp_id, vote_data})
        vote_data
      vote_data ->
        vote_data
    end
  end
  def get_user_agreement(user_id, camp_id) do
    process = get_user_server_process(user_id)
    {:ok, agreement} = GenServer.call(process, {:get_user_agreement, camp_id})
    case agreement do
      nil ->
        agreement = get_user_agreement_from_database(user_id, camp_id)
        put_user_agreement(process, {camp_id, agreement})
        agreement
      agreement ->
        agreement
    end
  end
  def get_user_agreement_map(user_id) do
    process = get_user_server_process(user_id)
    {:ok, agreement_map} = GenServer.call(process, :get_user_agreement_map)
    case agreement_map do
      nil ->
        agreement_map = UserCompare.create_user_agreement_map(user_id)
        put_user_agreement_map_to_server(process, agreement_map)
        agreement_map
      agreement_map ->
        agreement_map
    end
  end
  def get_user_disagreement_map(user_id) do
    process = get_user_server_process(user_id)
    {:ok, disagreement_map} = GenServer.call(process, :get_user_disagreement_map)
    case disagreement_map do
      nil ->
        disagreement_map = UserCompare.create_user_disagreement_map(user_id)
        put_user_disagreement_map_to_server(process, disagreement_map)
        disagreement_map
      disagreement_map ->
        disagreement_map
    end
  end
  def get_recent_camps(user_id, page) do
    process = get_user_server_process(user_id)
    {:ok, camps} = GenServer.call(process, {:get_recent_camps, page})
    case camps do
      nil ->
        {ids, camps} = UserHome.get_recent_camps_from_database(user_id)
        put_recent_camps_to_server(process, ids, camps)
        ids
        |> Enum.slice(((page * 20)), 20)
        |> Enum.map(&(camps[&1]))
      camps ->
        camps
    end
  end
  def get_camps_by_joined(user_id, page) do
    process = get_user_server_process(user_id)
    {:ok, camps} = GenServer.call(process, {:get_camps_by_joined, page})
    case camps do
      nil ->
        {ids, camps} = UserHome.get_camps_from_database(user_id, :joined)
        put_joined_camps_to_server(process, ids, camps)
        ids
        |> Enum.slice(((page * 20)), 20)
        |> Enum.map(&(camps[&1]))
      camps ->
        camps
    end
  end
  def get_camps_by_created(user_id, page) do
    process = get_user_server_process(user_id)
    {:ok, camps} = GenServer.call(process, {:get_camps_by_created, page})
    case camps do
      nil ->
        {ids, camps} = UserHome.get_camps_from_database(user_id, :created)
        put_created_camps_to_server(process, ids, camps)
        ids
        |> Enum.slice(((page * 20)), 20)
        |> Enum.map(&(camps[&1]))
      camps ->
        camps
    end
  end
  def store_user_camp_view(user_id, camp, type) do
    process = get_user_server_process(user_id)
    camp = %{
      id: camp.id,
      current_content: camp.current_content,
      created: camp.inserted_at,
      joined: time_joined(user_id, camp.id)
    }
    {:ok, recent_camp_ids} = GenServer.call(process, {:put_user_camp_view, camp, type})
    recent_camp_ids
  end
  def put_new_vote(user_id, camp_id, comment_id, _value, true) do
    process = get_user_server_process(user_id)
    GenServer.cast(process, {:put_new_vote, {camp_id, comment_id, 0}})
  end
  def put_new_vote(user_id, camp_id, comment_id, value, _updating?) do
    process = get_user_server_process(user_id)
    GenServer.cast(process, {:put_new_vote, {camp_id, comment_id, value}})
  end
  def get_camp_manifesto_votes(user_id, camp_id) do
    process = get_user_server_process(user_id)
    votes = GenServer.call(process, {:get_camp_manifesto_votes, camp_id})
    case votes do
      nil ->
        votes = Manifesto.get_camp_manifesto_votes(user_id, camp_id)
        put_camp_manifesto_votes(user_id, camp_id, votes)
        votes
      votes ->
        votes
    end
  end
  def get_manifesto_vote(user_id, camp_id, manifesto_id) do
    process = get_user_server_process(user_id)
    vote = GenServer.call(process, {:get_manifesto_vote, camp_id, manifesto_id})
    case vote do
      nil ->
        vote = Manifesto.get_vote(user_id, manifesto_id)
        put_manifesto_vote(user_id, camp_id, manifesto_id, vote)
        vote
      vote ->
        vote
    end
  end
  def put_manifesto_vote(user_id, camp_id, manifesto_id, vote) do
    process = get_user_server_process(user_id)
    GenServer.cast(process, {:put_manifesto_vote, camp_id, manifesto_id, vote})
  end
  def put_camp_manifesto_votes(user_id, camp_id, votes) do
    process = get_user_server_process(user_id)
    GenServer.cast(process, {:put_camp_manifesto_votes, camp_id, votes})
  end



  # CONTACTS
  def get_contact(user_id, contact_obfs_id) do
    process = get_user_server_process(user_id)
    {:ok, contact} = GenServer.call(process, {:get_user_contact, contact_obfs_id})
    contact
  end
  def get_user_contacts(user_id, type, page) do
    process = get_user_server_process(user_id)
    {:ok, contacts} = GenServer.call(process, {:get_user_contacts, type, page})
    case contacts do
      nil ->
        contacts = UserHome.get_user_contacts_from_database(user_id, type)
        put_user_contacts_to_server(process, contacts, type)
        contacts
      contacts ->
        contacts
    end
  end
  def get_contacts_by_search(user_id, query) do
    process = get_user_server_process(user_id)
    {:ok, contacts} = GenServer.call(process, {:get_contacts_by_search, query})
    contacts
  end

  # PRIVATE

  # MISC
  defp put_user_handle(process, handle) do
    GenServer.cast(process, {:put_user_handle, handle})
  end

  # CONTACTS
  defp put_user_contacts_to_server(process, contacts, type) do
    GenServer.cast(process, {:put_user_contacts_to_server, type, contacts})
  end


  # CAMP DATA
  defp put_user_agreement_map_to_server(process, agreement_map) do
    GenServer.cast(process, {:put_user_agreement_map, agreement_map})
  end
  defp put_user_disagreement_map_to_server(process, disagreement_map) do
    GenServer.cast(process, {:put_user_disagreement_map, disagreement_map})
  end
  defp put_recent_camps_to_server(process, ids, camps) do
    GenServer.cast(process, {:put_recent_camps_to_server, ids, camps})
  end
  defp put_joined_camps_to_server(process, ids, camps) do
    GenServer.cast(process, {:put_joined_camps_to_server, ids, camps})
  end
  defp put_created_camps_to_server(process, ids, camps) do
    GenServer.cast(process, {:put_created_camps_to_server, ids, camps})
  end
  defp put_user_explore_camps(process, ids, camps) do
    GenServer.cast(process, {:put_user_explore_camps, ids, camps})
  end
  defp put_user_agreement(process, camp_agreement_tuple) do
    GenServer.cast(process, {:put_user_agreement, camp_agreement_tuple})
  end
  defp put_user_vote_data(process, vote_data_tuple) do
    GenServer.cast(process, {:put_user_vote_data, vote_data_tuple})
  end
  def get_user_vote_data_from_database(user_id, camp_id) do
    q = from vote in Vote,
      where: vote.user_id == ^user_id,
      join: comment in Comment,
      where: comment.id == vote.comment_id,
      where: comment.camp_id == ^camp_id,
      select: {vote.comment_id, vote.value}
    Repo.all(q)
    |> Enum.into(%{})
  end
  defp get_user_agreement_from_database(user_id, camp_id) do
    q = from ratings in Rating,
      where: ratings.value in [4,5],
      where: ratings.user_id == ^user_id,
      where: ratings.camp_id == ^camp_id,
      select: count(ratings.id)
    count = List.first Repo.all(q)
    case count do
      0 ->
        false
      1 ->
        true
    end
  end



  # MISC MISC
  defp time_joined(user_id, camp_id) do
    q = from rating in Rating,
      where: rating.user_id == ^user_id,
      where: rating.camp_id == ^camp_id,
      select: rating.inserted_at
    Repo.all(q) |> List.first
  end
  defp get_user_server_process(user_id) do
    process = Process.whereis(:"UserStash-#{user_id}")
    case process do
      nil ->
        {:ok, process} = UserStash.start(user_id)
        process
      process ->
        process
    end
  end
end
