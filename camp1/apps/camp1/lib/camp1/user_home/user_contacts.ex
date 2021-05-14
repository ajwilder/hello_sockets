defmodule Camp1.UserHome.UserContacts do
  alias Camp1.Accounts
  alias Camp1.Accounts.{UserData, UserContact}
  alias Camp1.UserServer
  import Ecto.Query, warn: false
  alias Camp1.Repo

  def update_recently_chatted_contacts(user_id, user_ids) do
    current_list =
      query_user_contacts_user_data(user_id, :chatted)
      |> Repo.all
      |> List.first
    new_list = current_list -- user_ids
    new_list = List.flatten(user_ids, new_list)
    {:ok, _data} = Accounts.update_user_data(user_id, %{
      recently_chatted_contacts: new_list
      })
  end

  def get_initial_contacts(user_id) do
    contacts = get_user_contacts(user_id, :chatted, 0)
    case contacts do
      [] ->
        contacts = get_user_contacts(user_id, :added, 0)
        %{
          sub_menu: :contacts,
          type: :added,
          contacts: contacts
        }
      contacts ->
        %{
          sub_menu: :contacts,
          type: :chatted,
          contacts: contacts
        }
    end
  end

  def get_user_contacts(user_id, type, page) do
    UserServer.get_user_contacts(user_id, type, page)
  end

  def get_user_contacts_from_database(user_id, :alpha) do
    contacts =
      user_id
      |> query_user_contacts(:alpha)
      |> Repo.all
      |> Enum.map(&(Map.put &1, :contact_obfs_id, contact_obfs_id()))
    contacts
  end
  def get_user_contacts_from_database(user_id, type) do
    contact_ids =
      user_id
      |> query_user_contacts_user_data(type)
      |> Repo.all
      |> List.first
    case contact_ids do
      [] ->
        contacts =
          user_id
          |> query_user_contacts(type)
          |> Repo.all
          |> Enum.map(&(Map.put &1, :contact_obfs_id, contact_obfs_id()))
        id_list = Enum.map(contacts, &(&1.id))
        spawn(__MODULE__, :update_user_data_with_contacts, [type, id_list, user_id])
        contacts
      contact_ids ->
        contact_ids
        |> query_contacts_from_ids(user_id)
        |> query_contact_ids_in_order(contact_ids)
        |> Repo.all
        |> Enum.map(&(Map.put &1, :contact_obfs_id, contact_obfs_id()))
    end
  end

  defp query_user_contacts_user_data(user_id, :added) do
    from data in UserData,
      where: data.user_id == ^user_id,
      select: data.recently_added_contacts
  end
  defp query_user_contacts_user_data(user_id, :chatted) do
    from data in UserData,
      where: data.user_id == ^user_id,
      select: data.recently_chatted_contacts
  end

  defp query_contacts_from_ids(contact_ids, user_id) do
    from contact in UserContact,
      where: contact.user_id == ^user_id,
      where: contact.contact_id in ^contact_ids,
      order_by: contact.inserted_at,
      select: %{user_name: contact.user_name, contact_name: contact.contact_name, id: contact.contact_id}
  end

  def query_contact_ids_in_order(query, ids) do
    # https://stackoverflow.com/questions/59826383/elixir-ecto-query-preserving-order-of-output
    query \
    |> join(:inner, [s], o in fragment("SELECT * FROM UNNEST(?::int[]) WITH ORDINALITY AS o (contact_id, ordinal)", ^ids), on: s.contact_id == o.contact_id) \
    |> order_by([s, o], asc: o.ordinal)
  end

  defp query_user_contacts(user_id, :alpha) do
    from contact in UserContact,
      where: contact.user_id == ^user_id,
      order_by: contact.contact_name,
      select: %{user_name: contact.user_name, contact_name: contact.contact_name, id: contact.contact_id}
  end
  defp query_user_contacts(user_id, :added) do
    from contact in UserContact,
      where: contact.user_id == ^user_id,
      order_by: contact.inserted_at,
      select: %{user_name: contact.user_name, contact_name: contact.contact_name, id: contact.contact_id}
  end
  defp query_user_contacts(user_id, :chatted) do
    # TODO: this is currently the same as the above query.  Need to rewrite this query to query chat data for recently chatted contacts
    from contact in UserContact,
      where: contact.user_id == ^user_id,
      order_by: contact.inserted_at,
      select: %{user_name: contact.user_name, contact_name: contact.contact_name, id: contact.contact_id}
  end

  def update_user_data_with_contacts(:added, id_list, user_id) do
    Accounts.update_user_data(user_id, %{recently_added_contacts: id_list})
  end
  def update_user_data_with_contacts(:chatted, id_list, user_id) do
    Accounts.update_user_data(user_id, %{recently_chatted_contacts: id_list})
  end

  defp contact_obfs_id do
    :crypto.strong_rand_bytes(4) |> Base.url_encode64 |> binary_part(0, 4)
  end
end
