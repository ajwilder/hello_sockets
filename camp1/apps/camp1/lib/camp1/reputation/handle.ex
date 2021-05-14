defmodule Camp1.Reputation.Handle do
  use Ecto.Schema
  alias Camp1.Repo
  import Ecto.Changeset
  alias Camp1.Accounts.User
  alias Camp1.Public.Camp

  schema "handles" do
    field :value, :string
    belongs_to :camp, Camp
    belongs_to :user, User

    timestamps()
  end

  def changeset(handle, attrs) do
    handle
    |> cast(attrs, [:value, :camp_id, :user_id])
    |> validate_required([:value, :camp_id, :user_id])
    |> unsafe_validate_unique([:user_id, :camp_id], Repo)
    |> unique_constraint(:users_cant_have_two_names_in_one_camp, name: :users_cant_have_two_names_in_one_camp)
  end
end
