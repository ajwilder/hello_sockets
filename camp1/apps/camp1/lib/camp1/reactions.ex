defmodule Camp1.Reactions do
  import Ecto.Query, warn: false
  alias Camp1.Repo

  alias Camp1.Reactions.Rating
  alias Camp1.Reactions.Vote

  defdelegate create_or_update_vote(attrs, vote, updating?, old_vote?), to: Vote

  def list_ratings do
    Repo.all(Rating)
  end

  def list_votes do
    Repo.all(Vote)
  end

  def get_vote(id), do: Repo.get(Vote, id)
  def get_vote_by(attrs) do
     Repo.get_by(Vote, attrs)
  end
  def create_vote(attrs) do
    %Vote{}
    |> Vote.changeset(attrs)
    |> Repo.insert
  end

  def update_vote(vote = %Vote{}, attrs) do
    vote
    |> Vote.changeset(attrs)
    |> Repo.update
  end

  def get_rating!(id), do: Repo.get!(Rating, id)

  def create_rating(attrs \\ %{}) do
    %Rating{}
    |> Rating.changeset(attrs)
    |> Repo.insert()
  end

  def update_rating(%Rating{} = rating, attrs) do
    rating
    |> Rating.changeset(attrs)
    |> Repo.update()
  end

  def delete_rating(%Rating{} = rating) do
    Repo.delete(rating)
  end

  def change_rating(%Rating{} = rating, attrs \\ %{}) do
    Rating.changeset(rating, attrs)
  end
end
