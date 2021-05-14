defmodule Camp1.Repo.Migrations.CreateContributions do
  use Ecto.Migration

  def change do
    create table(:contributions) do
      add :value, :integer, null: false
      add :camp_id, references(:camps, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:contributions, [:camp_id])
    create index(:contributions, [:user_id])
    create index(:contributions, [:user_id, :camp_id])
  end
end
