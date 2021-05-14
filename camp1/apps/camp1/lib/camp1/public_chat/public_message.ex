defmodule Camp1.PublicChat.PublicMessage do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Accounts.User
  alias Camp1.Public.Camp

  schema "public_messages" do
    field :content, :string
    belongs_to :user, User
    belongs_to :camp, Camp

    timestamps()
  end

  @doc false
  def changeset(camp_message, attrs) do
    camp_message
    |> cast(attrs, [:content, :user_id, :camp_id])
    |> validate_required([:content])
  end
end
