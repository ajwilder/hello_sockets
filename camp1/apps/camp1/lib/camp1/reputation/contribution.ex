defmodule Camp1.Reputation.Contribution do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Accounts.User
  alias Camp1.Public.Camp

  schema "contributions" do
    field :value, :integer, null: false
    belongs_to :camp, Camp
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(contribution, attrs) do
    contribution
    |> cast(attrs, [:value, :camp_id, :user_id])
    |> validate_required([:value])
  end
end
