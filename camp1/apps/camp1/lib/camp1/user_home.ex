defmodule Camp1.UserHome do
  alias __MODULE__.{Explore, UserCamps, UserContacts, UserContactInvitations, UserChats, UserHandles, UserActivity}
  alias Camp1.UserServer

  defdelegate get_user_home_explore(user_id, type, page), to: Explore
  defdelegate create_user_explore(user_id), to: Explore

  defdelegate get_user_contacts(user_id, type, page), to: UserContacts
  defdelegate get_initial_contacts(user_id), to: UserContacts
  defdelegate get_user_contacts_from_database(user_id, type), to: UserContacts
  defdelegate update_recently_chatted_contacts(user_id, user_ids), to: UserContacts
  defdelegate get_user_contact_invitations(user_id), to: UserContactInvitations
  defdelegate get_user_contact_invite(user_id), to: UserContactInvitations

  defdelegate get_user_camps(user_id, type, page), to: UserCamps
  defdelegate get_recent_camps_from_database(user_id), to: UserCamps
  defdelegate get_recent_views_from_database(user_id), to: UserCamps
  defdelegate get_camps_from_database(user_id, type), to: UserCamps
  defdelegate store_recent_camp_view(user_id, camp, type), to: UserCamps

  defdelegate get_pending_chat_invitations(user_id), to: UserServer
  defdelegate get_pending_chat_invitation(user_id, invite_id), to: UserServer
  defdelegate get_chats_by_recent(user_id), to: UserServer
  defdelegate get_chats_by_created(user_id), to: UserServer
  defdelegate get_chats_by_alpha(user_id), to: UserServer
  defdelegate get_chats_by_search(user_id, query), to: UserServer
  defdelegate new_chat_invitation(invitation), to: UserServer

  defdelegate get_user_chats(user_id), to: UserChats
  defdelegate get_user_chat_invitations(user_id), to: UserChats
  defdelegate get_pending_invitations_from_db(user_id), to: UserChats
  defdelegate get_user_chat_invite(user_id), to: UserChats
  defdelegate accept_chat_invitation(invitation), to: UserChats
  defdelegate decline_chat_invitatation(invitation), to: UserChats
  defdelegate get_missed_messages(user_id), to: UserChats

  defdelegate get_user_activity(user_id), to: UserActivity


  def get_user_private(_user), do: %{}

  def get_user_survey(_user), do: %{}

  def get_user_camp_form(_user), do: %{}

  defdelegate get_default_user_handle(user_id), to: UserHandles
  defdelegate get_default_user_handle_from_database(user_id), to: UserHandles

end
