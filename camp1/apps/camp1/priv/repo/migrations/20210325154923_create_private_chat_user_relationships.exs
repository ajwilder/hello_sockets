defmodule Camp1.Repo.Migrations.CreatePrivateChatUserRelationships do
  use Ecto.Migration

  def change do
    create table(:private_chat_user_relationships) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :private_chat_id, references(:private_chats, on_delete: :delete_all)

      timestamps()
    end

    create index(:private_chat_user_relationships, [:user_id])
    create index(:private_chat_user_relationships, [:private_chat_id])
    create unique_index(:private_chat_user_relationships, [:user_id, :private_chat_id], name: :users_cant_join_twice)
  end
end
