defmodule Camp1.UserServer.UserStash do
  use GenServer
  alias Camp1.{UserServer, UserHome}
  alias Camp1.Accounts.UserData

  @timeout 24 * 60 * 60 * 1000
  @hibernate 60 * 60 * 1000
  @update 6 * 60 * 60 * 1000
  @update_user_data 5 * 60 * 1000


  # INIT
  def start(user_id) do
    name = :"UserStash-#{user_id}"
    {:ok, process} = GenServer.start(
      __MODULE__,
      %{
        user_explore_camps: nil,
        user_handle: nil,
        user_id: user_id,
        user_agreements: %{},
        user_agreement_map: nil,
        user_disagreement_map: nil,
        recent_camps: nil,
        recent_views: nil,
        camps_by_created: nil,
        camps_by_joined: nil,
        recently_chatted_contacts: nil,
        recently_chatted_contacts_real: [],
        recently_added_contacts: nil,
        alpha_contacts: nil,
        contacts: %{},
        contacts_by_id: %{},
        vote_data: %{},
        manifesto_vote_data: %{},
        camps: %{},
        pending_chat_invitations: [],
        chat_invitations: %{},
        chats_by_recent: [],
        chats_by_joined: [],
        chats_by_alphabetical: [],
        active_chats: [],
        open_chat: nil,
        chats: %{},
        missed_messages: 0,
        expiries: %{ vote_data: %{}}
        },
      name: name,
      hibernate_after: @hibernate
    )
    {:ok, process}
  end

  def init(stash) do
    :timer.send_after(@timeout, :job_timeout)
    :timer.send_after(@update, :update_stash)
    :timer.send_after(@update_user_data, :update_user_data)
    :timer.send_after(1, :init_chats_and_pending_invitations)
    {:ok, stash}
  end



  # CALLS
  # EXPLORE
  def handle_call({:get_user_explore_camps, page}, _from, stash = %{user_explore_camps: user_explore_camps, camps: camps}) do
    :timer.send_after(@timeout, :job_timeout)
    case user_explore_camps do
      nil ->
        {:reply, {:ok, nil}, stash}
      user_explore_camps ->
        user_explore_camps =
          user_explore_camps
          |> Enum.slice(((page * 20)), 20)
          |> Enum.map(&(camps[&1]))
        {:reply, {:ok, user_explore_camps}, stash}
    end
  end


  # CHAT INVITATIONS
  def handle_call(:get_pending_chat_invitations, _from, stash = %{pending_chat_invitations: pending_chat_invitations, chat_invitations: chat_invitations}) do
    :timer.send_after(@timeout, :job_timeout)
    invitations =
      pending_chat_invitations
      |> Enum.map(fn invitation -> chat_invitations[invitation] end)
    {:reply, {:ok, invitations}, stash}
  end
  def handle_call({:get_pending_chat_invitation, invite_id}, _from, stash = %{chat_invitations: chat_invitations}) do
    :timer.send_after(@timeout, :job_timeout)
    invitation = Map.get(chat_invitations, invite_id)
    {:reply, {:ok, invitation}, stash}
  end


  # CHATS
  def handle_call(:get_recent_chats, _from, stash = %{chats_by_recent: chats_by_recent, chats: chats}) do
    :timer.send_after(@timeout, :job_timeout)
    chats_by_recent =
      chats_by_recent
      |> Enum.map(fn chat -> chats[chat] end)
    {:reply, {:ok, chats_by_recent}, stash}
  end
  def handle_call(:get_chats_by_joined, _from, stash = %{chats_by_joined: chats_by_joined, chats: chats}) do
    :timer.send_after(@timeout, :job_timeout)
    chats_by_joined =
      chats_by_joined
      |> Enum.map(fn chat -> chats[chat] end)
    {:reply, {:ok, chats_by_joined}, stash}
  end
  def handle_call(:get_chats_by_alpha, _from, stash = %{chats_by_alphabetical: chats_by_alphabetical, chats: chats}) do
    :timer.send_after(@timeout, :job_timeout)
    chats_by_alphabetical =
      chats_by_alphabetical
      |> Enum.map(fn chat -> chats[chat] end)
    {:reply, {:ok, chats_by_alphabetical}, stash}
  end
  def handle_call({:get_chats_by_search, query}, _from, stash = %{chats: chats}) do
    :timer.send_after(@timeout, :job_timeout)
    chats =
      chats
      |> Map.keys
      |> Enum.map(&(chats[&1]))
      |> Enum.filter(fn chat ->
        Regex.match?(~r/#{query}/iu, chat.name)
      end)
    {:reply, {:ok, chats}, stash}
  end
  def handle_call(:get_active_chats, _from, stash = %{active_chats: active_chats}) do
    :timer.send_after(@timeout, :job_timeout)
    stash = Map.put(stash, :open_chat, nil)
    {:reply, {:ok, active_chats}, stash}
  end
  def handle_call(:get_missed_messages, _from, stash = %{missed_messages: missed_messages}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, missed_messages}, stash}
  end
  def handle_call({:is_authenticated?, chat_id}, _from, stash = %{chats: chats, chat_invitations: chat_invitations}) do
    ids =
      chat_invitations
      |> Map.values
      |> Enum.map(&(&1.private_chat_id))
      |> List.flatten(Map.keys(chats))

    {:reply, Enum.member?(ids, chat_id), stash}
  end

  # MISC
  def handle_call(:get_user_handle, _from, stash = %{user_handle: user_handle}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, user_handle}, stash}
  end

  # CAMP DATA
  def handle_call({:get_user_agreement, camp_id}, _from, stash = %{user_agreements: user_agreements}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, Map.get(user_agreements, camp_id)}, stash}
  end
  def handle_call({:get_user_vote_data, camp_id}, _from, stash = %{vote_data: vote_data}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, Map.get(vote_data, camp_id)}, stash}
  end
  def handle_call(:get_user_agreement_map, _from, stash = %{user_agreement_map: user_agreement_map}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, user_agreement_map}, stash}
  end
  def handle_call(:get_user_disagreement_map, _from, stash = %{user_disagreement_map: user_disagreement_map}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, user_disagreement_map}, stash}
  end
  def handle_call({:get_recent_camps, page}, _from, stash = %{recent_camps: recent_camps, camps: camps}) do
    :timer.send_after(@timeout, :job_timeout)
    case recent_camps do
      nil ->
        {:reply, {:ok, nil}, stash}
      recent_camps ->
        recent_camps =
          recent_camps
          |> Enum.slice(((page * 20)), 20)
          |> Enum.map(&(camps[&1]))
        {:reply, {:ok, recent_camps}, stash}
    end
  end
  def handle_call({:get_camps_by_created, page}, _from, stash = %{camps_by_created: camps_by_created, camps: camps}) do
    :timer.send_after(@timeout, :job_timeout)
    case camps_by_created do
      nil ->
        {:reply, {:ok, nil}, stash}
      camps_by_created ->
        camps_by_created =
          camps_by_created
          |> Enum.slice(((page * 20)), 20)
          |> Enum.map(&(camps[&1]))
        {:reply, {:ok, camps_by_created}, stash}
    end
  end
  def handle_call({:get_camps_by_joined, page}, _from, stash = %{camps_by_joined: camps_by_joined, camps: camps}) do
    :timer.send_after(@timeout, :job_timeout)
    case camps_by_joined do
      nil ->
        {:reply, {:ok, nil}, stash}
      camps_by_joined ->
        camps_by_joined =
          camps_by_joined
          |> Enum.slice(((page * 20)), 20)
          |> Enum.map(&(camps[&1]))
        {:reply, {:ok, camps_by_joined}, stash}
    end
  end
  def handle_call({:put_user_camp_view, camp, :unjoined}, _from, stash = %{camps: camps, recent_views: nil, user_id: user_id}) do
    {ids, new_camps} = UserHome.get_recent_views_from_database(user_id)
    camps =
      Map.merge(camps, new_camps)
      |> Map.put(camp.id, camp)
    recent_views =
      [camp.id | ids]
      |> Enum.uniq
    stash =
      stash
      |> Map.put(:camps, camps)
      |> Map.put(:recent_views, recent_views)
    {:reply, {:ok, recent_views}, stash}
  end
  def handle_call({:put_user_camp_view, camp, :unjoined}, _from, stash = %{camps: camps, recent_views: recent_views}) do
    camps = Map.put(camps, camp.id, camp)
    recent_views =
      [camp.id | recent_views]
      |> Enum.uniq
    stash =
      stash
      |> Map.put(:camps, camps)
      |> Map.put(:recent_views, recent_views)
    {:reply, {:ok, recent_views}, stash}
  end
  def handle_call({:put_user_camp_view, camp, :joined}, _from, stash = %{camps: camps, recent_camps: nil, user_id: user_id}) do
    {ids, new_camps} = UserHome.get_recent_camps_from_database(user_id)
    camps =
      Map.merge(camps, new_camps)
      |> Map.put(camp.id, camp)
    recent_camps =
      [camp.id | ids]
      |> Enum.uniq
    stash =
      stash
      |> Map.put(:camps, camps)
      |> Map.put(:recent_camps, recent_camps)
    {:reply, {:ok, recent_camps}, stash}
  end
  def handle_call({:put_user_camp_view, camp, :joined}, _from, stash = %{camps: camps, recent_camps: recent_camps}) do
    camps = Map.put(camps, camp.id, camp)
    recent_camps =
      [camp.id | recent_camps]
      |> Enum.uniq
    stash =
      stash
      |> Map.put(:camps, camps)
      |> Map.put(:recent_camps, recent_camps)
    {:reply, {:ok, recent_camps}, stash}
  end
  def handle_call({:get_manifesto_vote, camp_id, manifesto_id}, _from, stash = %{manifesto_vote_data: manifesto_vote_data}) do
    camp_manifesto_data = Map.get(manifesto_vote_data, camp_id)
    case camp_manifesto_data do
      nil ->
        {:reply, nil, stash}
      data ->
        vote_data = Map.get(data, manifesto_id)
        {:reply, vote_data, stash}
    end
  end
  def handle_call({:get_camp_manifesto_votes, camp_id}, _from, stash = %{manifesto_vote_data: manifesto_vote_data}) do
    {:reply,  Map.get(manifesto_vote_data, camp_id), stash}
  end

  # CONTACTS
  def handle_call({:get_user_contacts, :added, page}, _from, stash = %{recently_added_contacts: recently_added_contacts, contacts: contacts}) do
    :timer.send_after(@timeout, :job_timeout)
    case recently_added_contacts do
      nil ->
        {:reply, {:ok, nil}, stash}
      requested_contacts ->
        requested_contacts =
          requested_contacts
          |> Enum.slice(((page * 100)), 100)
          |> Enum.map(&(contacts[&1]))
        {:reply, {:ok, requested_contacts}, stash}
    end
  end
  def handle_call({:get_user_contacts, :chatted, page}, _from, stash = %{recently_chatted_contacts: recently_chatted_contacts, contacts: contacts}) do
    :timer.send_after(@timeout, :job_timeout)

    case recently_chatted_contacts do
      nil ->
        {:reply, {:ok, nil}, stash}
      requested_contacts ->
        requested_contacts =
          requested_contacts
          |> Enum.slice(((page * 100)), 100)
          |> Enum.map(&(contacts[&1]))
        {:reply, {:ok, requested_contacts}, stash}
    end
  end
  def handle_call({:get_user_contacts, :alpha, page}, _from, stash = %{alpha_contacts: alpha_contacts, contacts: contacts}) do
    :timer.send_after(@timeout, :job_timeout)
    case alpha_contacts do
      nil ->
        {:reply, {:ok, nil}, stash}
      requested_contacts ->
        requested_contacts =
          requested_contacts
          |> Enum.slice(((page * 100)), 100)
          |> Enum.map(&(contacts[&1]))
        {:reply, {:ok, requested_contacts}, stash}
    end
  end
  def handle_call({:get_user_contact, id}, _from, stash = %{contacts: contacts}) do
    {:reply, {:ok, Map.get(contacts, id)}, stash}
  end
  def handle_call({:get_contact_chats, id}, _from, stash = %{contacts: contacts, chats: chats}) do
    id = contacts[id].id
    chats =
      chats \
      |> Map.values \
      |> Enum.filter(fn chat -> Enum.member?(chat.user_ids, id) end)
    {:reply, {:ok, chats}, stash}
  end
  def handle_call({:get_contact_two_person_chat, id}, _from, stash = %{user_id: user_id, contacts: contacts, chats: chats}) do
    id = contacts[id].id
    chat =
      chats \
      |> Map.values \
      |> Enum.filter(fn chat -> (chat.user_ids == [user_id, id] || chat.user_ids == [id, user_id]) end)
      |> List.first
    {:reply, chat, stash}
  end
  def handle_call({:get_contacts_by_search, query}, _from, stash = %{contacts: contacts}) do
    :timer.send_after(@timeout, :job_timeout)
    contacts =
      contacts
      |> Map.keys
      |> Enum.map(&(contacts[&1]))
      |> Enum.filter(fn contact ->
        Regex.match?(~r/#{query}/iu, contact.contact_name)
      end)
    {:reply, {:ok, contacts}, stash}
  end


  # CASTS
  # EXPLORE
  def handle_cast({:put_user_explore_camps, ids, new_camps}, stash = %{camps: camps}) do
    camps = Map.merge(camps, new_camps)
    stash =
      stash
      |> Map.put(:camps, camps)
      |> Map.put(:user_explore_camps, ids)
    {:noreply, stash}
  end

  # CHATS
  def handle_cast(
    {:chat_updated, chat_id, latest_message, user_ids, message_count, send_update?},
    stash = %{chats: chats, chats_by_recent: chats_by_recent, recently_chatted_contacts: recently_chatted_contacts, contacts: contacts, contacts_by_id: contacts_by_id, open_chat: open_chat, missed_messages: missed_messages, recently_chatted_contacts_real: recently_chatted_contacts_real}
    ) do

    recently_chatted_contacts = update_recently_chatted_contacts(recently_chatted_contacts, user_ids, contacts, contacts_by_id)

    recently_chatted_contacts_real =
      recently_chatted_contacts_real -- [chat_id]
    recently_chatted_contacts_real = [chat_id | recently_chatted_contacts_real]


    chat = Map.get(chats, chat_id)
    chat = update_chat(chat, latest_message, (chat_id == open_chat || !send_update?), message_count)
    chats = Map.put(chats, chat_id, chat)

    missed_messages = update_missed_messages(missed_messages, message_count, (chat_id == open_chat || !send_update?))

    chats_by_recent = List.delete(chats_by_recent, chat_id)
    chats_by_recent = [chat_id | chats_by_recent]

    stash =
      stash
      |> Map.put(:chats, chats)
      |> Map.put(:chats_by_recent, chats_by_recent)
      |> Map.put(:missed_messages, missed_messages)
      |> Map.put(:recently_chatted_contacts_real, recently_chatted_contacts_real)
      |> Map.put(:recently_chatted_contacts, recently_chatted_contacts)

    {:noreply, stash}
  end
  def handle_cast({:put_active_chat, chat_map}, stash = %{active_chats: active_chats}) do
    active_chats =
      [chat_map | active_chats]
      |> Enum.slice(0,10)
    stash =
      stash
      |> Map.put(:active_chats, active_chats)
    {:noreply, stash}
  end
  def handle_cast({:chat_opened, chat_id}, stash = %{missed_messages: missed_messages, chats: chats, chats_by_recent: chats_by_recent} ) do
    chat = Map.get(chats, chat_id)
    case chat do
      nil ->
        {:noreply, stash}
      chat ->
        chat_missed_messages = Map.get(chat, :missed_messages, 0)
        missed_messages = missed_messages - chat_missed_messages
        chat = Map.drop(chat, [:missed_messages])
        chats = Map.put(chats, chat_id, chat)
        chats_by_recent = List.delete(chats_by_recent, chat_id)
        chats_by_recent = [chat_id | chats_by_recent]

        stash =
          stash
          |> Map.put(:chats, chats)
          |> Map.put(:open_chat, chat_id)
          |> Map.put(:missed_messages, missed_messages)
          |> Map.put(:chats_by_recent, chats_by_recent)
        {:noreply, stash}
    end
  end
  def handle_cast({:update_private_chat, chat_id, %{name: new_name}}, stash = %{chats: chats}) do
    chat =
      Map.get(chats, chat_id)
      |> Map.put(:name, new_name)
    chats = Map.put(chats, chat_id, chat)
    stash = Map.put(stash, :chats, chats)
    {:noreply, stash}
  end
  def handle_cast({:update_private_chat, chat_id, %{user_ids: user_ids}}, stash = %{chats: chats}) do
    chat =
      Map.get(chats, chat_id)
      |> Map.put(:user_ids, user_ids)
    chats = Map.put(chats, chat_id, chat)
    stash = Map.put(stash, :chats, chats)
    {:noreply, stash}
  end
  def handle_cast({:leave_chat, chat_id}, stash = %{chats: chats, active_chats: active_chats, chats_by_recent: chats_by_recent, chats_by_alphabetical: chats_by_alphabetical, chats_by_joined: chats_by_joined, missed_messages: missed_messages}) do
    chat = Map.get(chats, chat_id)
    chat_missed_messages = Map.get(chat, :missed_messages)
    missed_messages = update_missed_messages(missed_messages, chat_missed_messages)
    chats = Map.drop(chats, [chat_id])
    active_chats = List.delete(active_chats, chat_id)
    chats_by_recent = List.delete(chats_by_recent, chat_id)
    chats_by_alphabetical = List.delete(chats_by_alphabetical, chat_id)
    chats_by_joined = List.delete(chats_by_joined, chat_id)
    stash =
      stash
      |> Map.put(:chats, chats)
      |> Map.put(:active_chats, active_chats)
      |> Map.put(:chats_by_recent, chats_by_recent)
      |> Map.put(:chats_by_alphabetical, chats_by_alphabetical)
      |> Map.put(:chats_by_joined, chats_by_joined)
      |> Map.put(:missed_messages, missed_messages)
    {:noreply, stash}
  end
  def handle_cast(:chat_window_closed, stash) do
    {:noreply, Map.put(stash, :open_chat, nil)}
  end

  # CHAT INVITATAIONS
  def handle_cast({:new_pending_chat_invitation, invitation}, stash = %{chat_invitations: chat_invitations, pending_chat_invitations: pending_chat_invitations}) do
    :timer.send_after(@timeout, :job_timeout)
    chat_invitations = Map.put(chat_invitations, invitation.id, invitation)
    pending_chat_invitations = [invitation.id | pending_chat_invitations]
    stash =
      Map.put(stash, :chat_invitations, chat_invitations)
      |> Map.put(:pending_chat_invitations, pending_chat_invitations)
    {:noreply, stash}
  end
  def handle_cast({:update_chat_invitation, %{id: id, status: :declined}}, stash = %{pending_chat_invitations: pending_chat_invitations, chat_invitations: chat_invitations}) do
    chat_invitations = Map.drop(chat_invitations, [id])
    pending_chat_invitations = List.delete(pending_chat_invitations, id)
    stash =
      stash
      |> Map.put(:pending_chat_invitations, pending_chat_invitations)
      |> Map.put(:chat_invitations, chat_invitations)
    {:noreply, stash}
  end

  def handle_cast({:update_chat_invitation, invitation = %{id: id, status: :accepted, private_chat_id: private_chat_id}}, stash = %{pending_chat_invitations: pending_chat_invitations, chat_invitations: chat_invitations, chats_by_recent: chats_by_recent, chats: chats }) do
    chat_invitations = Map.drop(chat_invitations, [id])
    pending_chat_invitations = List.delete(pending_chat_invitations, id)

    chat = %{
      id: private_chat_id,
      name: invitation.name,
      updated_at: invitation.updated_at,
      handle: invitation.handle,
      user_ids: invitation.user_ids
    }
    chats_by_recent = List.delete(chats_by_recent, private_chat_id)
    chats_by_recent = [private_chat_id | chats_by_recent]
    chats = Map.put(chats, private_chat_id, chat)

    stash =
      stash
      |> Map.put(:pending_chat_invitations, pending_chat_invitations)
      |> Map.put(:chat_invitations, chat_invitations)
      |> Map.put(:chats_by_recent, chats_by_recent)
      |> Map.put(:chats, chats)

    {:noreply, stash}
  end


  # CAMP DATA
  def handle_cast({:put_user_agreement_map, user_agreement_map}, stash) do
    {:noreply, Map.put(stash, :user_agreement_map, user_agreement_map)}
  end
  def handle_cast({:put_user_disagreement_map, user_disagreement_map}, stash) do
    {:noreply, Map.put(stash, :user_disagreement_map, user_disagreement_map)}
  end
  def handle_cast({:put_recent_camps_to_server, ids, new_camps}, stash = %{camps: camps}) do
    camps = Map.merge(camps, new_camps)
    stash =
      stash
      |> Map.put(:camps, camps)
      |> Map.put(:recent_camps, ids)
    {:noreply, stash}
  end
  def handle_cast({:put_joined_camps_to_server, ids, new_camps}, stash = %{camps: camps}) do
    camps = Map.merge(camps, new_camps)
    stash =
      stash
      |> Map.put(:camps, camps)
      |> Map.put(:camps_by_joined, ids)
    {:noreply, stash}
  end
  def handle_cast({:put_created_camps_to_server, ids, new_camps}, stash = %{camps: camps}) do
    camps = Map.merge(camps, new_camps)
    stash =
      stash
      |> Map.put(:camps, camps)
      |> Map.put(:camps_by_created, ids)
    {:noreply, stash}
  end
  def handle_cast({:put_user_agreement, {camp_id, agreement}}, stash = %{user_agreements: user_agreements}) do
    user_agreements = Map.put(user_agreements, camp_id, agreement)
    {:noreply, Map.put(stash, :user_agreements, user_agreements)}
  end
  def handle_cast({:put_user_vote_data, {camp_id, camp_vote_data}}, stash = %{vote_data: vote_data, expiries: expiries = %{ vote_data: expires_vote_data}}) do
    expires_vote_data = Map.put(expires_vote_data, camp_id, Timex.shift(DateTime.utc_now, hours: 2))
    expiries = Map.put(expiries, :vote_data, expires_vote_data)
    vote_data = Map.put(vote_data, camp_id, camp_vote_data)
    stash =
      stash
      |> Map.put(:vote_data, vote_data)
      |> Map.put(:expiries, expiries)
    {:noreply, stash}
  end
  def handle_cast({:put_new_vote, {camp_id, comment_id, value}}, stash = %{vote_data: vote_data, user_id: user_id, expiries: expiries = %{ vote_data: expires_vote_data}}) do
    expires_vote_data = Map.put(expires_vote_data, camp_id, Timex.shift(DateTime.utc_now, hours: 2))
    expiries = Map.put(expiries, :vote_data, expires_vote_data)
    camp_vote_data = Map.get(vote_data, camp_id)

    camp_vote_data = make_sure_vote_data_loaded(camp_vote_data, user_id, camp_id)
    camp_vote_data = Map.put(camp_vote_data, comment_id, value)
    vote_data = Map.put(vote_data, camp_id, camp_vote_data)
    stash =
      stash
      |> Map.put(:vote_data, vote_data)
      |> Map.put(:expiries, expiries)
    {:noreply, stash}
  end
  def handle_cast({:put_manifesto_vote, camp_id, manifesto_id, vote}, stash = %{manifesto_vote_data: manifesto_vote_data}) do
    camp_manifesto_data = Map.get(manifesto_vote_data, camp_id, %{})
    camp_manifesto_data = Map.put(camp_manifesto_data, manifesto_id, vote)
    manifesto_vote_data = Map.put(manifesto_vote_data, camp_id, camp_manifesto_data)
    {:noreply, Map.put(stash, :manifesto_vote_data, manifesto_vote_data)}
  end
  def handle_cast({:put_camp_manifesto_votes, camp_id, votes}, stash = %{manifesto_vote_data: manifesto_vote_data}) do
    manifesto_vote_data = Map.put(manifesto_vote_data, camp_id, votes)
    {:noreply, Map.put(stash, :manifesto_vote_data, manifesto_vote_data)}
  end

  # MISC
  def handle_cast({:put_user_handle, handle}, stash) do
    {:noreply, Map.put(stash, :user_handle, handle)}
  end


  # CONTACTS
  def handle_cast({:put_user_contacts_to_server, :added, contacts_list}, stash = %{contacts: contacts, contacts_by_id: contacts_by_id}) do
    contacts = Enum.reduce(contacts_list, contacts, fn contact, contact_map ->
      Map.put_new(contact_map, contact.contact_obfs_id, contact)
    end)
    contacts_by_id = Enum.reduce(contacts_list, contacts_by_id, fn contact, contact_map ->
      Map.put_new(contact_map, contact.id, contact.contact_obfs_id)
    end)
    id_list = Enum.map(contacts_list, &(&1.contact_obfs_id))

    stash =
      Map.put(stash, :recently_added_contacts, id_list)
      |> Map.put(:contacts, contacts)
      |> Map.put(:contacts_by_id, contacts_by_id)
    {:noreply, stash}
  end
  def handle_cast({:put_user_contacts_to_server, :chatted, contacts_list}, stash = %{contacts: contacts, contacts_by_id: contacts_by_id}) do
    contacts = Enum.reduce(contacts_list, contacts, fn contact, contact_map ->
      Map.put_new(contact_map, contact.contact_obfs_id, contact)
    end)
    id_list = Enum.map(contacts_list, &(&1.contact_obfs_id))
    contacts_by_id = Enum.reduce(contacts_list, contacts_by_id, fn contact, contact_map ->
      Map.put_new(contact_map, contact.id, contact.contact_obfs_id)
    end)
    stash =
      Map.put(stash, :recently_chatted_contacts, id_list)
      |> Map.put(:contacts, contacts)
      |> Map.put(:contacts_by_id, contacts_by_id)
    {:noreply, stash}
  end
  def handle_cast({:put_user_contacts_to_server, :alpha, contacts_list}, stash = %{contacts: contacts, contacts_by_id: contacts_by_id}) do
    contacts = Enum.reduce(contacts_list, contacts, fn contact, contact_map ->
      Map.put_new(contact_map, contact.contact_obfs_id, contact)
    end)
    id_list = Enum.map(contacts_list, &(&1.contact_obfs_id))
    contacts_by_id = Enum.reduce(contacts_list, contacts_by_id, fn contact, contact_map ->
      Map.put_new(contact_map, contact.id, contact.contact_obfs_id)
    end)
    stash =
      Map.put(stash, :alpha_contacts, id_list)
      |> Map.put(:contacts, contacts)
      |> Map.put(:contacts_by_id, contacts_by_id)
    {:noreply, stash}
  end



  # INFO
  def handle_info(:init_chats_and_pending_invitations, stash = %{user_id: user_id}) do
    pending_invitations =
      UserHome.get_pending_invitations_from_db(user_id)

    invitations =
      pending_invitations \
      |> Enum.reduce(%{}, fn invite, map ->
        Map.put(map, invite.id, invite)
      end)

    pending_invitations = Enum.map(pending_invitations, fn invitation ->
      invitation.id
    end)

    missed_messages = UserData.get_missed_messages(user_id)

    chats_by_recent =
      UserHome.UserChats.get_recent_chats_from_db(user_id)

    chats =
      chats_by_recent \
      |> Enum.map(fn chat ->
        chat_id = Integer.to_string(chat.id)
        case missed_messages[chat_id] do
          nil ->
            chat
          message_count ->
            Map.put(chat, :missed_messages, message_count)
        end
      end)
      |> Enum.reduce(%{}, fn chat, map ->
        Map.put(map, chat.id, chat)
      end)

    chats_by_joined =
      Enum.sort_by(chats_by_recent, &(&1.inserted_at)) \
      |> Enum.map(fn chat -> chat.id end)

    chats_by_alphabetical =
      Enum.sort_by(chats_by_recent, &(String.downcase(&1.name))) \
      |> Enum.map(fn chat -> chat.id end)

    chats_by_recent = Enum.map(chats_by_recent, fn chat ->
      chat.id
    end)

    ids_to_drop_from_missed_messages = Map.keys(missed_messages) -- chats_by_recent

    missed_messages =
      missed_messages
      |> Map.drop(ids_to_drop_from_missed_messages)
      |> Map.values
      |> Enum.sum

    stash =
      stash
      |> Map.put(:pending_chat_invitations, pending_invitations)
      |> Map.put(:chat_invitations, invitations)
      |> Map.put(:chats_by_recent, chats_by_recent)
      |> Map.put(:chats_by_alphabetical, chats_by_alphabetical)
      |> Map.put(:chats_by_joined, chats_by_joined)
      |> Map.put(:chats, chats)
      |> Map.put(:missed_messages, missed_messages)

    {:noreply, stash}
  end
  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end
  def handle_info(:update_stash, stash) do
    stash =
      delete_camp_by_created(stash)
      |> delete_camps_by_joined()
      |> delete_expired_vote_data
      |> delete_unused_camps()

    :timer.send_after(@update, :update_stash)
    {:noreply, stash}
  end
  def handle_info(:update_user_data, stash = %{user_id: user_id, chats: chats, recently_chatted_contacts_real: recently_chatted_contact_ids}) do
    chats
    |> Map.values
    |> Enum.filter(fn chat -> chat[:missed_messages] end)
    |> Enum.reduce([], fn chat, list ->
      [{chat.id, chat.missed_messages} | list]
    end)
    |> UserData.update_missed_messages(user_id, recently_chatted_contact_ids)

    stash =
      stash
      Map.put(stash, :recently_chatted_contacts_real, [])

    :timer.send_after(@update_user_data, :update_user_data)
    {:noreply, stash}
  end


  # PRIVATE METHODS
  defp delete_unused_camps(stash = %{camps: camps}) do
    user_explore_camps =
      if is_nil(stash.user_explore_camps), do: [], else: stash.user_explore_camps
    recent_camps =
      if is_nil(stash.recent_camps), do: [], else: stash.recent_camps
    camps_by_created =
      if is_nil(stash.camps_by_created), do: [], else: stash.camps_by_created
    camps_by_joined =
      if is_nil(stash.camps_by_joined), do: [], else: stash.camps_by_joined
    camp_ids =
      recent_camps
      |> List.flatten(user_explore_camps)
      |> List.flatten(camps_by_created)
      |> List.flatten(camps_by_joined)
      |> Enum.uniq
    camp_ids = Map.keys(camps) -- camp_ids
    camps = Map.drop(camps, camp_ids)
    Map.put(stash, :camps, camps)
  end
  defp delete_camp_by_created(stash) do
    Map.put(stash, :camps_by_created, nil)
  end
  defp delete_camps_by_joined(stash) do
    Map.put(stash, :camps_by_joined, nil)
  end
  defp delete_expired_vote_data(stash = %{vote_data: vote_data, expiries: expiries = %{ vote_data: expires_vote_data}}) do
    map_to_delete = :maps.filter(fn _, exp -> DateTime.compare(exp, DateTime.utc_now) == :lt end, expires_vote_data)
    vote_data = Map.drop(vote_data, Map.keys(map_to_delete))
    expires_vote_data = Map.drop(expires_vote_data, Map.keys(map_to_delete))
    expiries = Map.put(expiries, :vote_data, expires_vote_data)
    Map.put(stash, :vote_data, vote_data)
    |> Map.put(:expiries, expiries)
  end
  defp make_sure_vote_data_loaded(nil, user_id, camp_id) do
    UserServer.get_user_vote_data_from_database(user_id, camp_id)
  end
  defp make_sure_vote_data_loaded(data, _user_id, _camp_id) do
    data
  end
  defp update_recently_chatted_contacts(recently_chatted_contacts, user_ids, contacts, contacts_by_id)
  defp update_recently_chatted_contacts(nil, _user_ids, _contacts, _contacts_by_id) do
    nil
  end
  defp update_recently_chatted_contacts(recently_chatted_contacts, user_ids, contacts, contacts_by_id) do
    contact_obfs_ids = Map.keys(contacts)
    contact_ids = Enum.map(contact_obfs_ids, &(contacts[&1].id))
    non_contacts = user_ids -- contact_ids
    user_ids_to_add = user_ids -- non_contacts

    recently_chatted_ids = Enum.map(recently_chatted_contacts, &(contacts[&1].id))
    new_recently_chatted_ids = recently_chatted_ids -- user_ids_to_add
    new_recently_chatted_ids = List.flatten(user_ids_to_add, new_recently_chatted_ids)



    Enum.map(new_recently_chatted_ids, &(contacts_by_id[&1]))
  end
  defp update_chat(chat, updated_at, open?, message_count) do
    chat = Map.put(chat, :updated_at, updated_at)
    case open? do
      true ->
        chat
      false ->
        count = Map.get(chat, :missed_messages, 0)
        Map.put(chat, :missed_messages, count + message_count)
    end
  end
  defp update_missed_messages(missed_messages, count, open?) do
    case open? do
      true ->
        0
      false ->
        missed_messages + count
    end
  end
  defp update_missed_messages(missed_messages, nil), do: missed_messages
  defp update_missed_messages(missed_messages, count), do: missed_messages - count

end
