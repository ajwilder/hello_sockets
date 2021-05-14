defmodule Camp1.Board.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Accounts.User
  alias Camp1.Public.Camp
  alias Camp1.Board.Comment
  alias Camp1.Reactions.Vote
  @timestamps_opts [type: :utc_datetime]

  schema "comments" do
    field :content, :string
    field :type, Camp1.Ecto.AtomType
    field :image_id, :integer
    field :document_id, :integer
    field :referenced_camp_id, :integer
    belongs_to :user, User
    belongs_to :camp, Camp
    belongs_to :parent, Comment
    has_many :children, Comment, foreign_key: :parent_id
    has_many :votes, Vote
    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    # TODO: creating a comment needs to simultaneously create an upvote from the user who created the comment
    comment
    |> cast(attrs, [:content, :user_id, :camp_id, :parent_id, :inserted_at, :comment_count, :image_id, :document_id, :referenced_camp_id])
    |> validate_required([:content])
  end


end
