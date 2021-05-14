defmodule Camp1.Repo.Migrations.CreateCampMessages do
  use Ecto.Migration

  def change do
    create table(:public_messages) do
      add :content, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :camp_id, references(:camps, on_delete: :nothing)

      timestamps()
    end

    create index(:public_messages, [:user_id])
    create index(:public_messages, [:camp_id])
  end
end
