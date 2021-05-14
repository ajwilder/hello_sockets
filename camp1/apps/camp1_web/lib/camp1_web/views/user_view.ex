defmodule Camp1Web.UserView do
  use Camp1Web, :view

  def select_user_home_template(expand, sub_menu)
  def select_user_home_template(nil, nil), do: "activity/_user_activity.html"
  def select_user_home_template("activity", nil), do: "activity/_user_activity.html"
  def select_user_home_template("home_explore", nil), do: "_user_home_explore.html"
  def select_user_home_template("contacts", nil), do: "contacts/_user_contacts.html"
  def select_user_home_template("contacts", "contacts"), do: "contacts/_user_contacts.html"
  def select_user_home_template("contacts", "invitations"), do: "contacts/_user_contacts.html"
  def select_user_home_template("contacts", "invite"), do: "contacts/_user_contacts.html"
  def select_user_home_template("your_camps", nil), do: "_user_your_camps.html"
  def select_user_home_template("private", nil), do: "_user_private.html"
  def select_user_home_template("survey", nil), do: "_user_survey.html"
  def select_user_home_template("chat", nil), do: "chat/_user_chat.html"
  def select_user_home_template("chat", "chats"), do: "chat/_user_chat.html"
  def select_user_home_template("chat", "invitations"), do: "chat/_user_chat.html"
  def select_user_home_template("chat", "invite"), do: "chat/_user_chat.html"
  def select_user_home_template("camp_form", nil), do: "_user_camp_form.html"

  def select_user_contacts_template(sub_menu)
  def select_user_contacts_template(:contacts), do: "contacts/_user_contacts_list.html"
  def select_user_contacts_template(:invitations), do: "contacts/_user_contact_invitations_list.html"
  def select_user_contacts_template(:invite), do: "contacts/_user_contact_invite.html"

  def select_user_chats_template(sub_menu)
  def select_user_chats_template(:chats), do: "chat/_user_chats_list.html"
  def select_user_chats_template(:invitations), do: "chat/_user_chat_invitations_list.html"
  def select_user_chats_template(:invite), do: "chat/_user_chat_invite_submenu.html"

end
