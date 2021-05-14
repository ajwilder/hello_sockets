defmodule Camp1.Private.PrivateHandle do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Repo
  alias Camp1.Private.{PrivateChat}
  alias Camp1.Accounts.User

  schema "private_handles" do
    field :value, :string
    belongs_to :private_chat, PrivateChat
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(handle, attrs) do
    handle
    |> cast(attrs, [:value, :private_chat_id, :user_id])
    |> validate_required([:value, :private_chat_id, :user_id])
    |> unsafe_validate_unique([:user_id, :private_chat_id], Repo)
    |> unique_constraint(:users_cant_have_two_names, name: :users_cant_have_two_names)
  end
end
