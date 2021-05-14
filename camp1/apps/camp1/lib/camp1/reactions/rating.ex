defmodule Camp1.Reactions.Rating do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Accounts.User
  alias Camp1.Public.Camp
  alias Camp1.Repo

  schema "ratings" do
    field :value, :integer
    belongs_to :camp, Camp
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(rating, attrs) do
    rating
    |> cast(attrs, [:value, :user_id, :camp_id])
    |> cast_assoc(:user)
    |> validate_required([:value, :user_id, :camp_id])
    |> unsafe_validate_unique([:user_id, :camp_id], Repo)
    |> unique_constraint(:users_cant_rate_twice, name: :users_cant_rate_twice)
  end
end
