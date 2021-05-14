defmodule Camp1.Public.CampRatingQueries do
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Camp1.Reactions.Rating

  def get_camp_ratings_map(camp_id) when is_binary(camp_id) do
    camp_id |> String.to_integer |> get_camp_ratings_map()
  end

  def get_camp_ratings_map(camp_id) when is_integer(camp_id) do
    camp_id
    |> query_camp_rating_with_count
    |> Repo.all
    |> counts_list_to_map
  end
  def get_camp_ratings_map(id_and_rating_list) when is_list(id_and_rating_list) do
    id_and_rating_list
    |> compose_query_with_list
    |> Repo.all
    |> counts_list_to_map
  end

  def get_users_by_camp_and_rating({camp_id, rating}) do
    query_users_by_camp_and_rating(camp_id, rating)
    |> Repo.all
  end

  def get_camp_ratings_map_for_user_list(camp_id, user_list) do
    query_camp_rating_with_count_with_users(camp_id, user_list)
    |> Repo.all
    |> counts_list_to_map
  end


  # queries


    def query_users_by_camp_and_rating(camp_id, rating) do
      from ratings in Rating,
        where: ratings.value == ^rating,
        where: ratings.camp_id == ^camp_id,
        select: ratings.user_id
    end

    def query_camp_rating(camp_id) do
      from rating in Rating,
        where: rating.camp_id == ^camp_id,
        select: rating.value
    end

    def query_camp_rating_with_count_with_users(camp_id, user_list) do
      from rating in Rating,
        where: rating.camp_id == ^camp_id,
        where: rating.user_id in ^user_list,
        select: [rating.value, count(rating.value)],
        group_by: rating.value
    end

    def query_camp_rating_with_count(camp_id) do
      from rating in Rating,
        where: rating.camp_id == ^camp_id,
        select: [rating.value, count(rating.value)],
        group_by: rating.value
    end

    def query_camp_rating_with_count_and_user_subquery(camp_id, query) do
      from rating in Rating,
        where: rating.camp_id == ^camp_id,
        where: rating.user_id in subquery(query),
        select: [rating.value, count(rating.value)],
        group_by: rating.value
    end

    def subquery_with_id_rating_user_list(id, rating, query) do
      from ratings in Rating,
        where: ratings.camp_id == ^id,
        where: ratings.value == ^rating,
        where: ratings.user_id in subquery(query),
        select: ratings.user_id
    end

    def compose_query_with_list(list, query \\ nil)
    def compose_query_with_list([], query), do: query
    def compose_query_with_list([head|tail], nil) when is_integer(head) do
      query = query_camp_rating_with_count(head)
      compose_query_with_list(tail, query)
    end
    def compose_query_with_list([head|tail], query) when is_integer(head) do
      query = query_camp_rating_with_count_and_user_subquery(head, query)
      compose_query_with_list(tail, query)
    end
    def compose_query_with_list([{id,rating}|tail], nil) do
      query = query_users_by_camp_and_rating(id, rating)
      compose_query_with_list(tail, query)
    end
    def compose_query_with_list([{id,rating}|tail], query) do
      query = subquery_with_id_rating_user_list(id, rating, query)
      compose_query_with_list(tail, query)
    end

    def counts_list_to_map(list, results \\ %{total: 0})
    def counts_list_to_map([], results), do: results
    def counts_list_to_map([[value|[count]]|tail], results) do
      current_total = Map.get results, :total
      results =
        results
        |> Map.put(value, count)
        |> Map.put(:total, current_total + count)
      counts_list_to_map(tail, results)
    end


end
