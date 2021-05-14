defmodule Camp1.Repo.Migrations.CreateSubjects do
  use Ecto.Migration

  def change do
    create table(:subjects) do
      add :content, :string
      add :parent_id, references(:subjects, on_delete: :nothing)

      timestamps()
    end

    create index(:subjects, [:parent_id])
  end
end
