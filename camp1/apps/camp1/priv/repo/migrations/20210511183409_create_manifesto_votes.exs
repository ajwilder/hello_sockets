defmodule Camp1.Repo.Migrations.CreateManifestoVotes do
  use Ecto.Migration

  def change do
    create table(:manifesto_votes) do
      add :value, :integer
      add :record_id, references(:manifesto_records, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create unique_index(:manifesto_votes, [:record_id, :user_id], name: :no_double_manifesto_votes)
    create index(:manifesto_votes, [:record_id])
    create index(:manifesto_votes, [:user_id])
  end
end
