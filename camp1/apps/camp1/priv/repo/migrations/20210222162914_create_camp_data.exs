defmodule Camp1.Repo.Migrations.CreateCampData do
  use Ecto.Migration

  def change do
    create table(:camp_data) do
      add :camp_id, references(:camps, on_delete: :nothing)
      add :comparison_map, :map, default: %{}
      add :child_count, :integer
      add :comment_count, :integer
      add :post_count, :integer
      add :message_count, :integer
      add :minimum_overlap, :integer, default: 1
      add :member_count, :integer, default: 0
      add :opponent_count, :integer, default: 0
      timestamps()
    end

    create index(:camp_data, [:camp_id])
  end
end
