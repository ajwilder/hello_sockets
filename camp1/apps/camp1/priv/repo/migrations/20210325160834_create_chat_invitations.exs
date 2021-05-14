defmodule Camp1.Repo.Migrations.CreateChatInvitations do
  use Ecto.Migration

  def change do
    create table(:chat_invitations) do
      add :inviter_id, references(:users, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :private_chat_id, references(:private_chats, on_delete: :nothing)
      add :status, :string, default: "pending"
      add :chat_name, :string
      add :message_content, :text
      add :inviter_handle, :string
      add :user_handle, :string
      timestamps()
    end

    create index(:chat_invitations, [:inviter_id])
    create index(:chat_invitations, [:user_id])
    create index(:chat_invitations, [:private_chat_id])
    create unique_index(:chat_invitations, [:inviter_id, :user_id, :private_chat_id], name: :users_cant_be_invited_to_same_chat_twice)
  end
end
