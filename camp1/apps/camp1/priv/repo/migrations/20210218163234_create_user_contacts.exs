defmodule Camp1.Repo.Migrations.CreateUserContacts do
  use Ecto.Migration

  def change do
    create table(:user_contacts) do
      add :user_id, references(:users, on_delete: :nothing)
      add :contact_id, references(:users, on_delete: :nothing)
      add :user_name, :string
      add :contact_name, :string
      timestamps()
    end
    create unique_index(:user_contacts, [:user_id, :contact_id], name: :users_cant_have_duplicate_contacts)

    create index(:user_contacts, [:user_id])
    create index(:user_contacts, [:contact_id])
    create index(:user_contacts, [:contact_id, :user_id])
  end
end
