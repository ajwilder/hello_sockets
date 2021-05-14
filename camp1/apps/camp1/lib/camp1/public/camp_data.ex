defmodule Camp1.Public.CampData do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Public.Camp

  schema "camp_data" do
    field :member_count, :integer
    field :opponent_count, :integer
    field :minimum_overlap, :integer
    field :child_count, :integer
    field :image_count, :integer
    field :document_count, :integer
    field :post_count, :integer
    field :message_count, :integer
    field :comparison_map, :map
    belongs_to :camp, Camp

    timestamps()
  end

  @doc false
  def changeset(camp_data, attrs) do
    camp_data
    |> cast(attrs, [:member_count, :opponent_count, :minimum_overlap, :message_count, :post_count, :document_count, :image_count, :child_count, :comparison_map])
    |> cast_assoc(:camp)
    |> validate_required([])
  end





end
