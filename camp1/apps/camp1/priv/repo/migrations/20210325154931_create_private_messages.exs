defmodule Camp1.Repo.Migrations.CreatePrivateMessages do
  use Ecto.Migration

  def change do
    create table(:private_messages) do
      add :content, :string
      add :user_id, references(:users, on_delete: :delete_all)
      add :private_chat_id, references(:private_chats, on_delete: :delete_all)
      add :type, :string

      timestamps()
    end

    create index(:private_messages, [:user_id])
    create index(:private_messages, [:private_chat_id])
  end
end
