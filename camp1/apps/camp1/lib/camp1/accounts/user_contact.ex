defmodule Camp1.Accounts.UserContact do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Accounts.User

  schema "user_contacts" do
    belongs_to :user, User
    belongs_to :contact, User
    field :user_name, :string
    field :contact_name, :string

    timestamps()
  end

  @doc false
  def changeset(user_contact, attrs) do
    user_contact
    |> cast(attrs, [:user_id, :contact_id, :contact_name, :user_name])
    |> validate_required([:user_id, :contact_id, :contact_name, :user_name])
  end
end
