defmodule Camp1.Repo.Migrations.CreateCamps do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string
      timestamps()
    end

    create table(:camps) do
      add :content, :text
      add :subject_id, references(:subjects, on_delete: :nothing)
      add :top_subject_id, references(:subjects, on_delete: :nothing)
      add :category_id, references(:categories, on_delete: :nothing)
      add :upload_id, :bigint
      add :inclusity, :integer
      add :speed, :integer
      timestamps()
    end

    create unique_index(:camps, [:upload_id], name: :one_camp_per_upload)
    create unique_index(:camps, [:content, :category_id], name: :one_camp_per_category_thing)

  end
end
