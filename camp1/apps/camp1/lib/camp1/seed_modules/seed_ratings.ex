defmodule Camp1.SeedRatings do
  alias Camp1.{Reactions, Accounts, Public}
  alias Camp1.Public.{Camp, CampOpponentRelationship, CampChildRelationship}
  alias Camp1.Repo
  import Ecto.Query, warn: false

  def add_ratings_to_camps() do
    user_ids = Accounts.list_users |> Enum.map(&(&1.id))
    user_ids
    |> Enum.each(fn user_id ->
      Public.list_camps
      |> Enum.each(fn camp ->
        rate_camp_and_opponents(camp, user_id)
      end)
    end)
  end

  def rate_camp_and_opponents(%{type: type, id: id}, user_id) do
    rating_range = rating_range_of_type(type)
    case rating_range do
      nil ->
        :ok
      rating_range ->
        rating_value = rand_int(rating_range)
        rate_camp(id, rating_value, user_id)
        rels = get_opponent_rels(id)
        Enum.each(rels, fn rel ->
          rate_camp(rel.opponent_id, opp_value(rating_value), user_id)
        end)
    end
  end



  def rate_camp(camp_id, rating_value, user_id) do
    {_status, _rating} = Reactions.create_rating(
      %{
        camp_id: camp_id,
        user_id: user_id,
        value: rating_value
      }
    )
  end

  defp rand_int(range) do
    Enum.random range
  end

  defp rating_range_of_type(type) do
    case type do
      :notion ->
        0..5
      :type ->
        nil
      :creation ->
        0..6
      :question ->
        nil
    end
  end

  def get_opponent_rels(camp_id) do
    q = from rel in CampOpponentRelationship,
      where: rel.camp_id == ^camp_id
    Repo.all(q)
  end

  def opp_value(value) do
    cond do
      value > 3 ->
        1
      value == 3 ->
        3
      value < 3 ->
        5
    end

  end
end
