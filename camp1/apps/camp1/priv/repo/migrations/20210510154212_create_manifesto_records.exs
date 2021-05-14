defmodule Camp1.Repo.Migrations.CreateManifestoRecords do
  use Ecto.Migration

  def change do
    create table(:manifesto_records) do
      add :content, :text
      add :status, :string
      add :camp_id, references(:camps, on_delete: :nothing)
      add :delta, :map, default: %{}
      add :previous_id, :bigint
      add :user_id, references(:users, on_delete: :nothing)
      add :approved_at, :utc_datetime
      timestamps()
    end

    create index(:manifesto_records, [:camp_id])
  end
end
