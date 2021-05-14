defmodule Camp1.Invitations.ContactInvitation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Accounts.User

  schema "contact_invitations" do
    belongs_to :user, User
    belongs_to :inviter, User
    field :status, Camp1.Ecto.AtomType
    field :source, Camp1.Ecto.AtomType
    field :source_id, :integer
    field :user_handle, :string
    field :inviter_handle, :string
    timestamps()
  end

  @doc false
  def changeset(contact_invitation, attrs) do
    contact_invitation
    |> cast(attrs, [:inviter_id, :source, :source_id, :status, :user_handle])
    |> validate_required([:inviter_id])
    |> unsafe_validate_unique([:user_id, :inviter_id], Repo)
    |> unique_constraint(:users_cant_invite_contacts_twice, name: :users_cant_invite_contacts_twice)
  end
end
