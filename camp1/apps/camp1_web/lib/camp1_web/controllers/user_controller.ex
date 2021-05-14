defmodule Camp1Web.UserController do
  use Camp1Web, :controller
  alias Camp1.UserHome

  def user_home(conn, params) do
    expand = Map.get(params, "1")
    sub_menu = Map.get(params, "2")
    data = get_expanded(expand, conn.assigns[:current_user].id, sub_menu)
    conn
    |> assign(:channel, :home)
    |> assign(:expand, expand)
    |> assign(:sub_menu, sub_menu)
    |> assign(:data, data)
    |> put_layout("user.html")
    |> render("user_home.html")
  end

  defp get_expanded(nil, user_id, _sub_menu) do
    UserHome.get_user_activity(user_id)
  end
  defp get_expanded("activity", user_id, _sub_menu) do
    UserHome.get_user_activity(user_id)
  end
  defp get_expanded("your_camps", user_id, nil) do
    UserHome.get_user_camps(user_id, :recent, 0)
  end
  defp get_expanded("home_explore", user_id, nil) do
    UserHome.get_user_home_explore(user_id, :type, 0)
  end
  defp get_expanded("contacts", user_id, nil) do
    UserHome.get_initial_contacts(user_id)
  end
  defp get_expanded("contacts", user_id, "contacts") do
    UserHome.get_initial_contacts(user_id)
  end
  defp get_expanded("contacts", user_id, "invitations") do
    UserHome.get_user_contact_invitations(user_id)
  end
  defp get_expanded("contacts", user_id, "invite") do
    UserHome.get_user_contact_invite(user_id)
  end
  defp get_expanded("chat", user_id, nil) do
    UserHome.get_user_chats(user_id)
  end
  defp get_expanded("chat", user_id, "chats") do
    UserHome.get_user_chats(user_id)
  end
  defp get_expanded("chat", user_id, "invitations") do
    UserHome.get_user_chat_invitations(user_id)
  end
  defp get_expanded("chat", user_id, "invite") do
    UserHome.get_user_chat_invite(user_id)
  end
  defp get_expanded(expand, user_id, _sub_menu) do
    data_function_name = String.to_atom("get_user_" <> expand)
    IO.inspect data_function_name
    apply(UserHome, data_function_name, [user_id])
  end
end
