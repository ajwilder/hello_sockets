defmodule Camp1.Public.CampOpponentRelationship do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Public.Camp
  alias Camp1.Repo

  schema "camp_opponent_relationships" do
    belongs_to :camp, Camp
    belongs_to :opponent, Camp
    timestamps()
  end

  @doc false
  def changeset(camp_alternate, attrs) do
    camp_alternate
    |> cast(attrs, [:camp_id, :opponent_id])
    |> validate_required([:camp_id, :opponent_id])
    |> unsafe_validate_unique([:opponent_id, :camp_id], Repo)
    |> unique_constraint(:no_identical_opponent_relationships, name: :no_identical_opponent_relationships)
  end
end
