defmodule Camp1.Private.PrivateChat do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Private.{PrivateMessage, PrivateHandle}

  schema "private_chats" do
    field :user_ids, {:array, :integer}
    field :name, :string
    has_many :messages, PrivateMessage, on_delete: :delete_all
    has_many :handles, PrivateHandle, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(private_chat, attrs) do
    private_chat
    |> cast(attrs, [:name, :updated_at, :user_ids])
    |> validate_required([:name])
  end
end
