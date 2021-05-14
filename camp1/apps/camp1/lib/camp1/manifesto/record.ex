defmodule Camp1.Manifesto.Record do
  use Ecto.Schema
  import Ecto.Changeset

  schema "manifesto_records" do
    field :content, :string
    field :status, Camp1.Ecto.AtomType
    field :delta, :map
    field :camp_id, :id
    field :user_id, :id
    field :previous_id, :id
    field :approved_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(record, attrs) do
    record
    |> cast(attrs, [:content, :status, :delta, :previous_id, :user_id, :camp_id, :approved_at])
    |> validate_required([])
  end
end
