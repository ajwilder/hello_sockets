defmodule Camp1.Public.ImageRelationship do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Public.Image

  schema "image_relationships" do
    field :other_id, :id
    field :type, :string
    belongs_to :image, Image

    timestamps()
  end

  @doc false
  def changeset(image_relationship, attrs) do
    image_relationship
    |> cast(attrs, [:other_id, :type, :image_id])
    |> validate_required([:other_id, :type, :image_id])
  end
end
