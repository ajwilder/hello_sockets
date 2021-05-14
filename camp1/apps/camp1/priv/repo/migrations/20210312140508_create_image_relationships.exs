defmodule Camp1.Repo.Migrations.CreateImageRelationships do
  use Ecto.Migration

  def change do
    create table(:image_relationships) do
      add :other_id, :bigint
      add :type, :string
      add :image_id, references(:images, on_delete: :nothing)

      timestamps()
    end

    create index(:image_relationships, [:image_id])
    create unique_index(:image_relationships, [:image_id, :other_id, :type], name: :no_identical_image_relationships)
  end
end
