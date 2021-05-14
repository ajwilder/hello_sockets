defmodule Camp1.Topics.Subject do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Public.Camp
  alias Camp1.Topics.Subject

  schema "subjects" do
    field :content, :string
    belongs_to :parent, Subject
    has_many :children, Subject, foreign_key: :parent_id
    has_many :camps, Camp
    timestamps()
  end

  @doc false
  def changeset(subject, attrs) do
    subject
    |> cast(attrs, [:content, :parent_id])
    |> validate_required([:content])
  end
end
