defmodule Camp1.Repo.Migrations.CreateContactInvitations do
  use Ecto.Migration

  def change do
    create table(:contact_invitations) do
      add :inviter_id, references(:users, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :status, :string, default: "pending"
      add :inviter_handle, :string
      add :user_handle, :string
      add :message_content, :text
      timestamps()
    end

    create index(:contact_invitations, [:inviter_id])
    create index(:contact_invitations, [:user_id])
    create unique_index(:contact_invitations, [:inviter_id, :user_id], name: :users_cant_invite_contacts_twice)
  end
end
