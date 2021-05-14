defmodule Camp1Web.UserHomeChannel do
  use Camp1Web, :channel
  alias Camp1.{UserHome, Accounts, Topics, UserServer, Invitations}
  alias Camp1Web.{UserView}
  alias Camp1.Private.{PrivateChatServer}
  alias Phoenix.View
  alias Camp1.UserServer.UserCompare

  def join("user_home_channel", _params, socket) do
    user = Accounts.get_user!(socket.assigns[:user_id])
    {:ok, :ok, assign(socket, :user, user)}
  end

  # EXPLORE
  def handle_in("init_explore", _params, socket) do
    data = UserHome.get_user_home_explore(socket.assigns[:user_id], :recent, 0)
    html = Phoenix.View.render_to_string(UserView, "_user_home_explore.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end


  # ACTIVITY
  def handle_in("init_activity", _params, socket) do
    data = UserHome.get_user_activity(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "activity/_user_activity.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end


  # CONTACTS
  def handle_in("init_contacts", _params, socket) do
    data = UserHome.get_initial_contacts(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "contacts/_user_contacts.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("expand_contacts_nav_contacts", _params, socket) do
    data = UserHome.get_initial_contacts(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "contacts/_user_contacts_list.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("expand_contacts_nav_invite", _params, socket) do
    data = UserHome.get_user_contact_invite(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "contacts/_user_contact_invite.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("expand_contacts_nav_invitations", _params, socket) do
    data = UserHome.get_user_contact_invitations(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "contacts/_user_contact_invitations_list.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("new_app_invite", %{"name" => name, "email" => email}, socket) do
    {message, invitation} = Invitations.create_app_invitation(%{
      email: email,
      inviter_email: socket.assigns.user.email,
      inviter_id: socket.assigns.user.id,
      inviter_handle: name
      })
    case message do
      :ok ->
        html =
          Phoenix.View.render_to_string(UserView, "contacts/_user_app_invite_success.html", %{invitation: invitation})
        {:reply, {:ok, %{html: html}}, socket}
      :error ->
        html =
          Phoenix.View.render_to_string(UserView, "contacts/_user_app_invite_fail.html", %{changeset: invitation})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("compare_contact", %{"contact" => contact}, socket) do
    contact = UserServer.get_contact(socket.assigns[:user_id], contact)
    case contact do
      nil ->
        {:reply, {:ok, %{html: nil}}, socket}
      contact ->
        compare = UserCompare.compare_two_users(socket.assigns[:user_id], contact.id)
        subject_names = Topics.TopicsServer.get_top_subject_names
        html =
          Phoenix.View.render_to_string(UserView, "contacts/_user_compare.html", %{compare: compare, subject_names: subject_names, compare_type: :user, contact: contact})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("show_chat_invite", %{"contact" => contact}, socket) do
    chat = UserServer.get_contact_two_person_chat(socket.assigns[:user_id], contact)
    contact = UserServer.get_contact(socket.assigns[:user_id], contact)
    case contact do
      nil ->
        {:reply, {:ok, %{html: nil}}, socket}
      contact ->
        html =
          Phoenix.View.render_to_string(UserView, "contacts/_user_contact_chat_invite.html", %{contact: contact, chat: chat})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("show_contact_chats", %{"contact" => contact}, socket) do
    chats = UserServer.get_contact_chats(socket.assigns[:user_id], contact)
    case chats do
      nil ->
        {:reply, {:ok, %{html: nil}}, socket}
      chats ->
        html =
          Phoenix.View.render_to_string(UserView, "contacts/_user_contact_chats.html", %{chats: chats, contact: contact})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("show_all_chats", %{"contact" => contact}, socket) do
    contact = UserServer.get_contact(socket.assigns[:user_id], contact)

    # Make sure user_id in chat members
    chats = UserServer.get_chats_by_recent(socket.assigns[:user_id])
    chats = Enum.filter(chats, fn chat -> !Enum.member?(chat.user_ids, contact.id) end)

    # Make sure member not already invited
    invitations =
      UserHome.get_pending_chat_invitations(socket.assigns[:user_id])
      |> Enum.filter(fn invite -> invite.user_id == contact.id end)
      |> Enum.map(fn invite -> invite.private_chat_id end)
    chats = Enum.filter(chats, fn chat -> !Enum.member?(invitations, chat.id) end)


    html =
      Phoenix.View.render_to_string(UserView, "contacts/_user_invite_all_chats.html", %{chats: chats, contact: contact})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("new_chat_invite", %{"contact" => contact, "chat" => chat}, socket) do
    chat = String.to_integer(chat)
    contact = UserServer.get_contact(socket.assigns[:user_id], contact)
    handles = PrivateChatServer.get_chat_handles(chat) |> Map.keys()
    authenticated =
      handles |> Enum.member?(socket.assigns[:user_id])
    case {contact, authenticated} do
      {nil, _} ->
        {:reply, {:ok, %{html: nil}}, socket}
      {contact, true} ->
        {:ok, invitation} = Invitations.create_chat_invitation(%{
          user_handle: contact.contact_name,
          inviter_handle: contact.user_name,
          user_id: contact.id,
          inviter_id: socket.assigns[:user_id],
          private_chat_id: chat,
          chat_name: PrivateChatServer.get_chat_name(chat)
          })

        # Add this invite to pending invites on UserServer
        UserServer.new_chat_invitation(invitation)

        # Notify user of invite in real time
        name = PrivateChatServer.get_chat_name(chat)
        popup_html = Phoenix.View.render_to_string(UserView, "popups/_popup_chat_invitation.html", %{invitation: invitation, name: name, user_count: length(handles)})
        Camp1Web.Endpoint.broadcast("user_rt_channel:#{contact.id}", "new_chat_invitation", %{popup_html: popup_html, dom_id: "chatInvitationPopup#{invitation.id}"})

        # Send back invite success to inviter
        html =
          Phoenix.View.render_to_string(UserView, "chat/_user_chat_invite_success.html", %{contact: contact})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("new_chat_invite", %{"contact" => contact}, socket) do
    contact = UserServer.get_contact(socket.assigns[:user_id], contact)
    case contact do
      nil ->
        {:reply, {:ok, %{html: nil}}, socket}
      contact ->
        UserHome.UserChats.new_invitation(contact, socket.assigns[:user_id])

        # Send back invite success to inviter
        html =
          Phoenix.View.render_to_string(UserView, "chat/_user_chat_invite_success.html", %{contact: contact})
        {:reply, {:ok, %{html: html}}, socket}
    end
  end
  def handle_in("sort_contacts", %{"sort_by" => "recent"}, socket) do
    contacts = UserServer.get_user_contacts(socket.assigns[:user_id], :chatted, 0)
    html = Phoenix.View.render_to_string(UserView, "contacts/_contacts_list.html", %{data: contacts})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("sort_contacts", %{"sort_by" => "added"}, socket) do
    contacts = UserServer.get_user_contacts(socket.assigns[:user_id], :added, 0)
    html = Phoenix.View.render_to_string(UserView, "contacts/_contacts_list.html", %{data: contacts})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("sort_contacts", %{"sort_by" => "alpha"}, socket) do
    contacts = UserServer.get_user_contacts(socket.assigns[:user_id], :alpha, 0)
    html = Phoenix.View.render_to_string(UserView, "contacts/_contacts_list.html", %{data: contacts})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("search_contacts", %{"query" => query}, socket) do
    contacts = UserServer.get_contacts_by_search(socket.assigns[:user_id], query)
    html = Phoenix.View.render_to_string(UserView, "contacts/_contacts_list.html", %{data: contacts})
    {:reply, {:ok, %{html: html}}, socket}
  end


  # CAMPS
  def handle_in("init_camps", _params, socket) do
    data = UserHome.get_user_camps(socket.assigns[:user_id], :recent, 0)
    html = Phoenix.View.render_to_string(UserView, "_user_your_camps.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("load_more_camps", %{"page" => page, "type" => type}, socket) do
    type = String.to_atom(type)
    page = String.to_integer(page)
    data = UserHome.get_user_camps(socket.assigns[:user_id], type, page)
    html = Phoenix.View.render_to_string(UserView, "_camps_list.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("load_new_camps", %{"type" => type}, socket) do
    type = String.to_atom(type)
    data = UserHome.get_user_camps(socket.assigns[:user_id], type, 0)
    html = Phoenix.View.render_to_string(UserView, "_user_camps_list.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end


  # MISC IN DEVELOPMENT
  def handle_in("init_private", _params, socket) do
    {socket, private_html} = get_html(socket, :private)
    {:reply, {:ok, %{html: private_html}}, socket}
  end
  def handle_in("init_survey", _params, socket) do
    {socket, survey_html} = get_html(socket, :survey)
    {:reply, {:ok, %{html: survey_html}}, socket}
  end
  def handle_in("init_camp_form", _params, socket) do
    {socket, camp_form_html} = get_html(socket, :camp_form)
    {:reply, {:ok, %{html: camp_form_html}}, socket}
  end


  # CHATS
  def handle_in("init_chat", _params, socket) do
    data = UserHome.get_user_chats(socket.assigns[:user_id])
    chat_html = Phoenix.View.render_to_string(UserView, "chat/_user_chat.html", %{data: data})
    {:reply, {:ok, %{html: chat_html}}, socket}
  end
  def handle_in("expand_chats_nav_chats", _params, socket) do
    data = UserHome.get_user_chats(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "chat/_user_chats_list.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("expand_chats_nav_invitations", _params, socket) do
    data = UserHome.get_user_chat_invitations(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "chat/_user_chat_invitations_list.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("expand_chats_nav_invite", _params, socket) do
    data = UserHome.get_user_chat_invite(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "chat/_user_chat_invite_submenu.html", %{data: data})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("sort_chats", %{"sort_by" => "recent"}, socket) do
    chats = UserServer.get_chats_by_recent(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "chat/_chats_list.html", %{data: %{chats: chats}})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("sort_chats", %{"sort_by" => "created"}, socket) do
    chats = UserServer.get_chats_by_created(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "chat/_chats_list.html", %{data: %{chats: chats}})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("sort_chats", %{"sort_by" => "alpha"}, socket) do
    chats = UserServer.get_chats_by_alpha(socket.assigns[:user_id])
    html = Phoenix.View.render_to_string(UserView, "chat/_chats_list.html", %{data: %{chats: chats}})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("search_chats", %{"query" => query}, socket) do
    chats = UserServer.get_chats_by_search(socket.assigns[:user_id], query)
    html = Phoenix.View.render_to_string(UserView, "chat/_chats_list.html", %{data: %{chats: chats}})
    {:reply, {:ok, %{html: html}}, socket}
  end
  def handle_in("chat_invite_details", %{"chat" => chat}, socket) do
    chat = String.to_integer chat
    authenticated =
      UserServer.authenticate_chat_details(socket.assigns[:user_id], chat)

    case authenticated do
      true ->
        data = PrivateChatServer.get_chat_details(chat)
        html = Phoenix.View.render_to_string(UserView, "chat/_chat_details.html", %{data: data})
        {:reply, {:ok, %{html: html}}, socket}
      false ->
        {:error, :unauthenticated}
    end
  end
  def handle_in("toggle_edit_chat", %{"chat" => chat}, socket) do
    chat = String.to_integer chat
    authenticated =
      UserServer.authenticate_chat_details(socket.assigns[:user_id], chat)

    case authenticated do
      true ->
        chat = PrivateChatServer.get_chat_details(chat)
        html = Phoenix.View.render_to_string(UserView, "chat/_chat_edit_form.html", %{chat: chat})
        {:reply, {:ok, %{html: html}}, socket}
      false ->
        {:error, :unauthenticated}
    end
  end
  def handle_in("chat_edit_submit", %{"chat" => chat, "new_name" => new_name}, socket) do
    chat = String.to_integer chat
    authenticated =
      UserServer.authenticate_chat_details(socket.assigns[:user_id], chat)

    case authenticated do
      true ->
        PrivateChatServer.update_chat_name(chat, new_name, socket.assigns[:user_id])
        html = Phoenix.View.render_to_string(UserView, "chat/_chat_edit_success.html", %{})
        {:reply, {:ok, %{html: html}}, socket}
      false ->
        {:error, :unauthenticated}
    end
  end
  def handle_in("leave_chat", %{"chat" => chat}, socket) do
    chat = String.to_integer chat
    authenticated =
      UserServer.authenticate_chat_details(socket.assigns[:user_id], chat)

    case authenticated do
      true ->
        chat_name = PrivateChatServer.leave_chat(chat, socket.assigns[:user_id])
        html = Phoenix.View.render_to_string(UserView, "chat/_chat_left.html", %{chat_name: chat_name})
        {:reply, {:ok, %{html: html}}, socket}
      false ->
        {:error, :unauthenticated}
    end
  end
  def handle_in("new_chat", %{"name" => name, "contacts" => contacts}, socket) do
    Enum.each(contacts, fn contact ->
      contact = UserServer.get_contact(socket.assigns[:user_id], contact)
      case contact do
        nil ->
          :ok
        contact ->
          UserHome.UserChats.new_invitation(contact, socket.assigns[:user_id], name)
      end
    end)

    {:reply, :ok, socket}
  end

  # CATCHALL FUNCTION
  defp get_html(socket, section) do
    case socket.assigns[section] do
      nil ->
        data_function_name = String.to_atom("get_user_" <> Atom.to_string(section))
        data = apply(UserHome, data_function_name, [socket.assigns[:user_id]])
        view_function_name = "_user_" <> Atom.to_string(section) <> ".html"
        html = apply(View, :render_to_string, [UserView, view_function_name, %{data: data}])
        {assign(socket, section, html), html}
      html ->
        {socket, html}
    end
  end

end
