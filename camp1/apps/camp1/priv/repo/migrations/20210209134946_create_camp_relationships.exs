defmodule Camp1.Repo.Migrations.CreateCampRelationshipsAndOpponents do
  use Ecto.Migration

  def change do
    create table(:camp_child_relationships) do
      add :parent_id, references(:camps, on_delete: :nothing)
      add :child_id, references(:camps, on_delete: :nothing)
      add :type, :string
      timestamps()
    end

    create table(:camp_opponent_relationships) do
      add :camp_id, references(:camps, on_delete: :nothing)
      add :opponent_id, references(:camps, on_delete: :nothing)
      timestamps()
    end

    create index(:camp_child_relationships, [:parent_id])
    create index(:camp_child_relationships, [:child_id])
    create unique_index(:camp_child_relationships, [:parent_id, :child_id], name: :no_identical_child_relationships)

    create index(:camp_opponent_relationships, [:camp_id])
    create index(:camp_opponent_relationships, [:opponent_id])
    create unique_index(:camp_opponent_relationships, [:camp_id, :opponent_id], name: :no_identical_opponent_relationships)
  end
end
