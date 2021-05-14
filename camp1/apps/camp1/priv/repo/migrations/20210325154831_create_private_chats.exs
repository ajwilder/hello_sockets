defmodule Camp1.Repo.Migrations.CreatePrivateChat do
  use Ecto.Migration

  def change do
    create table(:private_chats) do
      add :name, :string
      add :user_ids, {:array, :integer}, default: []

      timestamps()
    end

  end
end
