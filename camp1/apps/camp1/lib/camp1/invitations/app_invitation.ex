defmodule Camp1.Invitations.AppInvitation do
  use Ecto.Schema
  alias Camp1.Accounts.User
  import Ecto.Changeset
  alias Camp1.Repo

  schema "app_invitations" do
    field :email, :string
    field :inviter_email, :string
    field :inviter_handle, :string
    field :status, Camp1.Ecto.AtomType
    belongs_to :inviter, User
    belongs_to :user, User
    timestamps()
  end

  @doc false
  def changeset(app_invitation, attrs) do
    app_invitation
    |> cast(attrs, [:email, :inviter_id, :user_id, :inviter_email, :inviter_handle, :status])
    |> validate_required([:email, :inviter_id])
    |> unsafe_validate_unique([:email, :inviter_id], Repo)
    |> unique_constraint(:users_cant_invite_emails_twice, name: :users_cant_invite_emails_twice)
  end
end
