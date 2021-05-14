defmodule Camp1.Manifesto.ManifestoVote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "manifesto_votes" do
    field :value, :integer
    field :record_id, :id
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(manifesto_vote, attrs) do
    manifesto_vote
    |> cast(attrs, [:value, :record_id, :user_id])
    |> validate_required([:value])
  end
end
