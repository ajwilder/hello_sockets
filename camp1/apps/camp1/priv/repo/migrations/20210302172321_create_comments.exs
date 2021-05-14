defmodule Camp1.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :content, :text
      add :type, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :camp_id, references(:camps, on_delete: :nothing)
      add :referenced_camp_id, :bigint
      add :image_id, :bigint
      add :document_id, :bigint
      add :parent_id, references(:comments, on_delete: :nothing)
      timestamps()
    end

    create index(:comments, [:parent_id])
    create index(:comments, [:user_id])
    create index(:comments, [:camp_id])
    create index(:comments, [:referenced_camp_id])
  end
end
