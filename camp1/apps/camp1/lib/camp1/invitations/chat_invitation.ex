defmodule Camp1.Invitations.ChatInvitation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Repo
  alias Camp1.Accounts.User
  alias Camp1.Private.PrivateChat

  schema "chat_invitations" do
    belongs_to :user, User
    belongs_to :inviter, User
    belongs_to :private_chat, PrivateChat
    field :status, Camp1.Ecto.AtomType
    field :source, Camp1.Ecto.AtomType
    field :source_id, :integer
    field :chat_name, :string
    field :user_handle, :string
    field :inviter_handle, :string

    timestamps()
  end

  @doc false
  def changeset(chat_invitation, attrs) do
    chat_invitation
    |> cast(attrs, [:user_id, :inviter_id, :source, :source_id, :status, :user_handle, :inviter_handle, :private_chat_id, :chat_name])
    |> validate_required([:user_id, :inviter_id])
    |> unsafe_validate_unique([:user_id, :inviter_id, :private_chat_id], Repo)
    |> unique_constraint(:users_cant_be_invited_to_same_chat_twice, name: :users_cant_be_invited_to_same_chat_twice)
  end
end
