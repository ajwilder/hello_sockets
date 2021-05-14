defmodule Camp1.Repo.Migrations.CreateRatings do
  use Ecto.Migration

  def change do
    create table(:ratings) do
      add :value, :integer
      add :camp_id, references(:camps, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:ratings, [:camp_id])
    create index(:ratings, [:user_id])
    create unique_index(:ratings, [:user_id, :camp_id], name: :users_cant_rate_twice)
  end
end
