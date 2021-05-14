defmodule Camp1.Repo.Migrations.CreateUserData do
  use Ecto.Migration

  def change do
    create table(:user_data) do
      add :user_id, references(:users, on_delete: :nothing)
      add :missed_messages, :map, default: %{}
      add :recently_added_contacts, {:array, :integer}, default: []
      add :recently_chatted_contacts, {:array, :integer}, default: []
      add :recent_camps, {:array, :integer}, default: []
      add :recent_views, {:array, :integer}, default: []
      add :default_handle, :string
      timestamps()
    end
    create index(:user_data, [:user_id])

  end
end
