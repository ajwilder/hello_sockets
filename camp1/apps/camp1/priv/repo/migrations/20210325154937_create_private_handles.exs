defmodule Camp1.Repo.Migrations.CreateHandles do
  use Ecto.Migration

  def change do
    create table(:private_handles) do
      add :value, :string
      add :private_chat_id, references(:private_chats, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:private_handles, [:private_chat_id])
    create index(:private_handles, [:user_id])
    create unique_index(:private_handles, [:user_id, :private_chat_id], name: :users_cant_have_two_names_in_one_private_chat)
  end
end
