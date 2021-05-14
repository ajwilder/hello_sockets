defmodule Camp1.Public.CampChildRelationship do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Public.Camp
  alias Camp1.Repo

  schema "camp_child_relationships" do
    belongs_to :parent, Camp
    belongs_to :child, Camp
    field :type, Camp1.Ecto.AtomType
    timestamps()
  end

  @doc false
  def changeset(camp_child_relationship, attrs) do
    camp_child_relationship
    |> cast(attrs, [:type, :parent_id, :child_id])
    |> validate_required([:type, :parent_id, :child_id])
    |> unsafe_validate_unique([:parent_id, :child_id], Repo)
    |> unique_constraint(:no_identical_child_relationships, name: :no_identical_child_relationships)
  end
end
