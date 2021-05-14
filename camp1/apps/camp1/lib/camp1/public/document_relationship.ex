defmodule Camp1.Public.DocumentRelationship do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Public.Document

  schema "document_relationships" do
    field :other_id, :id
    field :type, :string
    belongs_to :document, Document

    timestamps()
  end

  @doc false
  def changeset(image_relationship, attrs) do
    image_relationship
    |> cast(attrs, [:other_id, :type, :document_id])
    |> validate_required([:other_id, :type, :document_id])
  end
end
