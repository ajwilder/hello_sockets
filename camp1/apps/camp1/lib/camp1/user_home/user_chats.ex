defmodule Camp1.UserHome.UserChats do
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Camp1.Invitations.{ChatInvitation}
  alias Camp1.{Invitations, Private, UserServer, UserHome}
  alias Camp1.Private.{PrivateChatServer, PrivateChat, PrivateHandle}
  alias Camp1Web.UserView



  def new_invitation(contact, user_id, chat_name \\ nil) do
    {:ok, invitation} = Invitations.create_chat_invitation(%{
      user_handle: contact.contact_name,
      inviter_handle: contact.user_name,
      user_id: contact.id,
      inviter_id: user_id,
      chat_name: chat_name
      })

    # Add this invite to pending invites on UserServer
    UserHome.new_chat_invitation(invitation)

    # Notify user of invite in real time
    popup_html = Phoenix.View.render_to_string(UserView, "popups/_popup_chat_invitation.html", %{invitation: invitation, name: nil, user_count: nil})
    Camp1Web.Endpoint.broadcast("user_rt_channel:#{contact.id}", "new_chat_invitation", %{popup_html: popup_html, dom_id: "chatInvitationPopup#{invitation.id}"})
  end


  # GETTERS
  def get_user_chats(user_id) do
    %{
      sub_menu: :chats,
      chats: UserServer.get_chats_by_recent(user_id),
    }
  end
  def get_recent_chats_from_db(user_id) do
    query_recent_chats(user_id)
    |> Repo.all
  end
  def get_user_chat_invitations(user_id) do
    %{
      sub_menu: :invitations,
      sent_invitations: get_pending_sent_invitations(user_id),
      received_invitations: get_pending_received_invitations(user_id),
    }
  end
  def get_user_chat_invite(user_id) do
    %{
      contacts: UserHome.get_user_contacts(user_id, :chatted, 0),
      sub_menu: :invite,
    }
  end
  def get_missed_messages(user_id) do
    UserServer.get_missed_messages(user_id)
  end
  def get_pending_invitations_from_db(user_id) do
    get_pending_received_invitations(user_id) ++ get_pending_sent_invitations(user_id)
  end

  # ACCEPTORS
  def accept_chat_invitation(invitation = %{private_chat_id: nil}) do
    name = get_invitation_name(invitation)
    {:ok, data = %{private_chat: private_chat}} = Private.create_private_chat_with_users(
      %{
        user_ids: [invitation.user_id, invitation.inviter_id],
        name: name
      },
      [{invitation.user_id, invitation.user_handle}, {invitation.inviter_id, invitation.inviter_handle}]
    )
    {:ok, invitation} =
      Invitations.update_chat_invitation(
        invitation.id,
        %{status: :accepted, private_chat_id: private_chat.id}
      )
    # Fire up the chat server
    PrivateChatServer.init_chat_server(data)

    user_ids =
      data
      |> Map.drop([:private_chat, :first_message])
      |> Map.keys
    user_ids
    |> Enum.each(fn id ->
      # update chat information on each user server
      UserServer.update_chat_invitation(id, %{id: invitation.id, status: :accepted, private_chat_id: private_chat.id, handle: invitation.user_handle, name: private_chat.name, updated_at: private_chat.inserted_at, user_ids: user_ids})
      # Broadcast chat information to user RT channel
      html = Phoenix.View.render_to_string(UserView, "widget/_chat_widget_chat.html", %{chat: %{name: private_chat.name, id: private_chat.id, missed_messages: nil}})
      if id == invitation.user_id do
        Camp1Web.Endpoint.broadcast!("user_rt_channel:#{id}", "invitation_update", %{
          invitation_status: :accepted, private_chat_id: private_chat.id, html: html
          })
      else
        popup_html = Phoenix.View.render_to_string(UserView, "popups/_popup_chat_acceptance.html", %{invitation: invitation})
        Camp1Web.Endpoint.broadcast!("user_rt_channel:#{id}", "invitation_update", %{
          private_chat_id: private_chat.id, invitation_status: :accepted, handle: invitation.user_handle, html: html, popup_html: popup_html, dom_id: "chatAcceptancePopup#{private_chat.id}"
          })
      end
    end)
    invitation
  end
  def accept_chat_invitation(_invitation = %{id: invitation_id, private_chat_id: chat_id}) do
    {:ok, invitation} = Invitations.update_chat_invitation(invitation_id, %{status: :accepted})
    user_id = invitation.user_id
    inviter_id = invitation.inviter_id

    attrs = %{
      private_chat_id: chat_id,
      user_id: user_id,
      value: invitation.user_handle
    }
    {:ok, _handle} = Private.create_private_chat_handle(attrs)
    private_chat = PrivateChatServer.add_user_to_chat(attrs)

    message = Private.new_message(%{
      private_chat_id: chat_id,
      content: "#{invitation.user_handle} added to chat on #{Date.to_string DateTime.utc_now}",
      user_id: user_id,
      type: :admin
      })
    html = Phoenix.View.render_to_string(UserView, "chat/_chat_messages.html", messages: [message], id: chat_id, init: false)
    Camp1Web.Endpoint.broadcast!("private_chat_channel:#{chat_id}", "new_message", %{html: html})

    # update chat information on each user server
    UserServer.update_chat_invitation(user_id, %{id: invitation.id, status: :accepted, private_chat_id: chat_id, handle: invitation.user_handle, name: private_chat.name, updated_at: private_chat.latest_message, user_ids: private_chat.user_ids})
    UserServer.update_chat_invitation(inviter_id, %{id: invitation.id, status: :accepted, private_chat_id: chat_id, handle: invitation.user_handle, name: private_chat.name, updated_at: private_chat.latest_message, user_ids: private_chat.user_ids})

    # Broadcast chat information to user RT channel
    html = Phoenix.View.render_to_string(UserView, "widget/_chat_widget_chat.html", %{chat: private_chat})
    Camp1Web.Endpoint.broadcast!("user_rt_channel:#{user_id}", "invitation_update", %{
      invitation_status: :accepted, private_chat_id: private_chat.id, html: html
      })

    popup_html = Phoenix.View.render_to_string(UserView, "popups/_popup_chat_acceptance.html", %{invitation: invitation})
    Camp1Web.Endpoint.broadcast!("user_rt_channel:#{inviter_id}", "invitation_update", %{
      private_chat_id: private_chat.id, invitation_status: :accepted, handle: invitation.user_handle, html: html, popup_html: popup_html, dom_id: "chatAcceptancePopup#{private_chat.id}"
      })
    invitation
  end
  def decline_chat_invitatation(invitation) do
    {:ok, invitation} =
      Invitations.update_chat_invitation(invitation.id, %{status: :declined})

    # update chat information on each user server
    UserServer.update_chat_invitation(invitation.user_id, %{id: invitation.id, status: :declined})
    UserServer.update_chat_invitation(invitation.inviter_id, %{id: invitation.id, status: :declined})
    invitation
  end
  def user_left_chat(chat_id, user_handle) do
    message = Private.new_message(%{
      private_chat_id: chat_id,
      content: "#{user_handle} left chat on #{Date.to_string DateTime.utc_now}",
      user_id: nil,
      type: :admin
      })
    html = Phoenix.View.render_to_string(UserView, "chat/_chat_messages.html", messages: [message], id: chat_id, init: false)
    Camp1Web.Endpoint.broadcast!("private_chat_channel:#{chat_id}", "new_message", %{html: html})
  end


  # PRIVATE GETTERS
  defp get_pending_received_invitations(user_id) do
    q = from invitation in ChatInvitation,
      where: invitation.user_id == ^user_id,
      order_by: {:desc, invitation.inserted_at},
      where: invitation.status == :pending,
      select: %{
        status: invitation.status,
        source: invitation.source,
        user_handle: invitation.user_handle,
        inviter_handle: invitation.inviter_handle,
        inserted_at: invitation.inserted_at,
        id: invitation.id,
        type: :received,
        private_chat_id: invitation.private_chat_id,
        inviter_id: invitation.inviter_id,
        user_id: invitation.user_id,
        chat_name: invitation.chat_name,
      }
    Repo.all(q)
  end
  defp get_pending_sent_invitations(user_id) do
    q = from invitation in ChatInvitation,
      where: invitation.inviter_id == ^user_id,
      order_by: {:desc, invitation.inserted_at},
      where: invitation.status == :pending,
      select: %{
        status: invitation.status,
        source: invitation.source,
        user_handle: invitation.user_handle,
        inviter_handle: invitation.inviter_handle,
        inserted_at: invitation.inserted_at,
        id: invitation.id,
        type: :sent,
        private_chat_id: invitation.private_chat_id,
        inviter_id: invitation.inviter_id,
        user_id: invitation.user_id,
        chat_name: invitation.chat_name,
      }
    Repo.all(q)
  end
  defp get_received_invitations(user_id) do
    q = from invitation in ChatInvitation,
      where: invitation.user_id == ^user_id,
      order_by: {:desc, invitation.inserted_at},
      select: %{
        status: invitation.status,
        source: invitation.source,
        user_handle: invitation.user_handle,
        inviter_handle: invitation.inviter_handle,
        inserted_at: invitation.inserted_at,
        id: invitation.id,
        private_chat_id: invitation.private_chat_id,
        inviter_id: invitation.inviter_id,
        user_id: invitation.user_id,
        chat_name: invitation.chat_name,
      }
    Repo.all(q)
  end
  defp get_sent_invitations(user_id) do
    q = from invitation in ChatInvitation,
      where: invitation.inviter_id == ^user_id,
      order_by: {:desc, invitation.inserted_at},
      select: %{
        status: invitation.status,
        source: invitation.source,
        user_handle: invitation.user_handle,
        inviter_handle: invitation.inviter_handle,
        inserted_at: invitation.inserted_at,
        id: invitation.id,
        private_chat_id: invitation.private_chat_id,
        inviter_id: invitation.inviter_id,
        user_id: invitation.user_id,
        chat_name: invitation.chat_name,
      }
    Repo.all(q)
  end

  # PRIVATE QUERIES
  defp query_recent_chats(user_id) do
    from handle in PrivateHandle,
      where: handle.user_id == ^user_id,
      join: chat in PrivateChat,
      order_by: {:desc, chat.updated_at},
      where: chat.id == handle.private_chat_id,
      limit: 500,
      select: %{
        updated_at: chat.updated_at,
        inserted_at: chat.inserted_at,
        name: chat.name,
        handle: handle.value,
        id: chat.id,
        user_ids: chat.user_ids
      }
  end

  # HELPERS
  defp get_invitation_name(invitation = %{chat_name: nil}) do
    "#{invitation.user_handle} and #{invitation.inviter_handle} Chat"
  end
  defp get_invitation_name(%{chat_name: chat_name}), do: chat_name
  defp get_invitation_name(invitation) do
    "#{invitation.user_handle} and #{invitation.inviter_handle} Chat"
  end
end
