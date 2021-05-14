defmodule Camp1.Private.PrivateMessage do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Private.{PrivateChat}
  alias Camp1.Accounts.User

  schema "private_messages" do
    field :content, :string
    field :type, Camp1.Ecto.AtomType
    belongs_to :private_chat, PrivateChat
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(private_message, attrs) do
    private_message
    |> cast(attrs, [:content, :private_chat_id, :user_id, :type])
    |> validate_required([:content, :private_chat_id])
  end
end
