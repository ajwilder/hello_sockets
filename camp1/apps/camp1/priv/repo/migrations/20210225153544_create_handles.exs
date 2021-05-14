defmodule Camp1.Repo.Migrations.CreateHandles do
  use Ecto.Migration

  def change do
    create table(:handles) do
      add :value, :string
      add :camp_id, references(:camps, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:handles, [:camp_id])
    create index(:handles, [:user_id])
    create unique_index(:handles, [:user_id, :camp_id], name: :users_cant_have_two_names_in_one_camp)
  end
end
