defmodule Camp1.UserHome.Explore do
  import Ecto.Query, warn: false
  alias Camp1.Public.Camp
  alias Camp1.Repo
  alias Camp1.Reactions.Rating
  alias Camp1.UserServer

  def get_user_home_explore(user_id, _type, page) do
    %{
      camps: UserServer.get_user_home_explore(user_id, page),
      next_page: page + 1,
      type: :recent
    }
  end

  def create_user_explore(user_id) do
    ids_query = query_user_rated_camp_ids(user_id)
    camp_list = random_camps(ids_query) |> Repo.all()
    camps = Enum.reduce(camp_list, %{}, fn camp, map ->
      Map.put(map, camp.id, camp)
    end)
    ids = Enum.map(camp_list, &(&1.id))
    {ids, camps}
  end

  defp query_user_rated_camp_ids(user_id) do
    from ratings in Rating,
      where: ratings.user_id == ^user_id,
      select: ratings.camp_id
  end

  defp random_camps(ids_query) do
    from camp in Camp,
      where: camp.id not in subquery(ids_query),
      order_by: fragment("RANDOM()"),
      limit: 200,
      select: %{id: camp.id, current_content: camp.current_content, created: camp.inserted_at}
  end



end
