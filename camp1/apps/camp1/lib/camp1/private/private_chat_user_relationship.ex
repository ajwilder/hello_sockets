defmodule Camp1.Private.PrivateChatUserRelationship do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Private.{PrivateMessage, PrivateChat, PrivateChatUserRelationship, Handle}
  alias Camp1.Accounts.User
  alias Camp1.Repo

  schema "private_chat_user_relationships" do
    belongs_to :private_chat, PrivatChat
    belongs_to :user, User
    timestamps()
  end

  @doc false
  def changeset(private_chat_user_relationship, attrs) do
    private_chat_user_relationship
    |> cast(attrs, [:private_chat_id, :user_id])
    |> validate_required([:private_chat_id, :user_id])
    |> unsafe_validate_unique([:user_id, :private_chat_id], Repo)
    |> unique_constraint(:users_cant_join_twice, name: :users_cant_join_twice)
  end
end
