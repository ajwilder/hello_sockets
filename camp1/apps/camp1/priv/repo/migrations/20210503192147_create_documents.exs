defmodule Camp1.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :size, :bigint
      add :hash, :string, size: 64
      add :camp_id, references(:camp, on_delete: :nothing)

      timestamps()
    end
    create table(:document_relationships) do
      add :other_id, :bigint
      add :type, :string
      add :document_id, references(:documents, on_delete: :delete_all)

      timestamps()
    end

    create index(:document_relationships, [:document_id])
    create unique_index(:document_relationships, [:document_id, :other_id, :type], name: :no_identical_document_relationships)
  end
end
