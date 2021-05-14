defmodule Camp1.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :value, :integer
      add :comment_id, references(:comments, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create unique_index(:votes, [:user_id, :comment_id], name: :users_cant_vote_twice)

    create index(:votes, [:comment_id])
    create index(:votes, [:user_id])
  end
end
