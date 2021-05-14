defmodule Camp1.Repo.Migrations.CreateAppInvitations do
  use Ecto.Migration

  def change do
    create table(:app_invitations) do
      add :email, :string
      add :inviter_id, references(:users, on_delete: :nothing)
      add :status, :string
      add :inviter_email, :string
      add :inviter_handle, :string
      add :message_content, :text
      add :user_id, references(:users, on_delete: :nothing)
      timestamps()
    end
    create unique_index(:app_invitations, [:inviter_id, :email], name: :users_cant_invite_emails_twice)

    create index(:app_invitations, [:inviter_id])
  end
end
