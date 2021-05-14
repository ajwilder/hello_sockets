defmodule Camp1.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :size, :bigint
      add :hash, :string, size: 64
      add :camp_id, references(:camp, on_delete: :nothing)

      timestamps()
    end

  end
end
