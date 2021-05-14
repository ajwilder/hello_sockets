defmodule Camp1.Accounts.UserData do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Accounts.{User, UserData}
  alias Camp1.Repo
  import Ecto.{Query}, warn: false

  schema "user_data" do
    field :recent_camps, {:array, :integer}
    field :recent_views, {:array, :integer}
    field :recently_added_contacts, {:array, :integer}
    field :recently_chatted_contacts, {:array, :integer}
    field :default_handle, :string
    field :handles, :map
    field :missed_messages, :map
    belongs_to :user, User
    timestamps()
  end

  @doc false
  def changeset(user_data, attrs) do
    user_data
    |> cast(attrs, [:recent_camps, :recent_views, :default_handle, :handles, :recently_chatted_contacts, :recently_added_contacts, :missed_messages])
  end


  def add_missed_messages(user_id, list_of_id_count_tuples) do
    user_data = Repo.get_by(UserData, user_id: user_id)
    missed_messages = user_data.missed_messages
    missed_messages = update_missed_messages_from_list(missed_messages, list_of_id_count_tuples)
    user_data
    |> UserData.changeset(%{missed_messages: missed_messages})
    |> Repo.update()
  end

  def update_missed_messages_from_list(missed_messages, list) do
    Enum.reduce(list, missed_messages, fn {chat_id, count}, map ->
      chat_id = Integer.to_string(chat_id)
      case map[chat_id] do
        nil ->
          Map.put(map, chat_id, count)
        already_missed ->
          Map.put(map, chat_id, count + already_missed)
      end
    end)
  end

  def update_missed_messages(list_of_id_count_tuples, user_id, new_recently_chatted_contacts) do
    missed_messages = update_missed_messages_from_list(%{}, list_of_id_count_tuples)

    user_data = Repo.get_by(UserData, user_id: user_id)

    recently_chatted_contacts =
      user_data.recently_chatted_contacts -- new_recently_chatted_contacts
    recently_chatted_contacts = List.flatten(new_recently_chatted_contacts, recently_chatted_contacts)

    user_data
    |> UserData.changeset(%{
      missed_messages: missed_messages,
      recently_chatted_contacts: recently_chatted_contacts
      })
    |> Repo.update()
  end

  def get_missed_messages(user_id) do
    q = from data in UserData,
      where: data.user_id == ^user_id,
      select: data.missed_messages
    Repo.all(q)
    |> List.first
  end
end
