defmodule Camp1.Reactions.Vote do
  use Ecto.Schema
  import Ecto.Changeset
  alias Camp1.Board.Comment
  alias Camp1.Accounts.User
  alias Camp1.{Repo, Reactions}

  schema "votes" do
    field :value, :integer
    belongs_to :comment, Comment
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:value, :comment_id, :user_id])
    |> validate_required([:value, :comment_id, :user_id])
    |> unsafe_validate_unique([:user_id, :comment_id], Repo)
    |> unique_constraint(:users_cant_vote_twice, name: :users_cant_vote_twice)
  end




  # old vote being updated to 0
  def create_or_update_vote(%{comment_id: comment_id, user_id: user_id}, nil, true, true ) do
    vote = Reactions.get_vote_by(%{comment_id: comment_id, user_id: user_id})
    {:ok, vote} = Reactions.update_vote(vote, %{value: 0})
    vote
  end
  # old vote being updated to value
  def create_or_update_vote(%{comment_id: comment_id, user_id: user_id, value: value}, nil, false, true ) do
    vote = Reactions.get_vote_by(%{comment_id: comment_id, user_id: user_id})
    {:ok, vote} = Reactions.update_vote(vote, %{value: value})
    vote
  end
  # recent vote being updated to 0
  def create_or_update_vote(_attrs, vote, true, _) do
    {:ok, vote} = Reactions.update_vote(vote, %{value: 0})
    vote
  end
  # totally new vote
  def create_or_update_vote(attrs, nil, false, false) do
    {:ok, vote} = Reactions.create_vote(attrs)
    vote
  end
  # updating recent vote
  def create_or_update_vote(%{value: value}, vote, false, _) do
    {:ok, vote} = Reactions.update_vote(vote, %{value: value})
    vote
  end
end
