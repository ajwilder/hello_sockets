defmodule Camp1.UserHome.UserCamps do
  alias Camp1.Accounts.UserData
  alias Camp1.Accounts
  alias Camp1.Public.Camp
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Camp1.UserServer
  alias Camp1.Reactions.Rating

  def get_user_camps(user_id, :recent, page) do
    %{
      camps: UserServer.get_recent_camps(user_id, page),
      next_page: page + 1,
      type: :recent
    }
  end
  def get_user_camps(user_id, :joined, page) do
    %{
      camps: UserServer.get_camps_by_joined(user_id, page),
      next_page: page + 1,
      type: :recent
    }
  end
  def get_user_camps(user_id, :created, page) do
    %{
      camps: UserServer.get_camps_by_created(user_id, page),
      next_page: page + 1,
      type: :recent
    }
  end

  def get_camps_from_database(user_id, type) do
    ids = get_camps_ids_from_data_base(user_id, type)
    camps = query_camps_from_ids(ids, user_id)
      |> Repo.all()
      |> Enum.reduce(%{}, fn camp, map ->
        Map.put(map, camp.id, camp)
      end)
    {ids, camps}
  end

  def get_recent_views_from_database(user_id) do
    ids = get_recent_view_ids_from_data_base(user_id)
    case ids do
      [] ->
        {[], %{}}
      ids ->
        camps = query_camps_from_ids(ids, user_id)
          |> Repo.all()
          |> Enum.reduce(%{}, fn camp, map ->
            Map.put(map, camp.id, camp)
          end)
        {ids, camps}
    end
  end

  def get_recent_camps_from_database(user_id) do
    ids = get_recent_camps_ids_from_data_base(user_id)
    camps = query_camps_from_ids(ids, user_id)
      |> Repo.all()
      |> Enum.reduce(%{}, fn camp, map ->
        Map.put(map, camp.id, camp)
      end)
    {ids, camps}
  end

  def store_recent_camp_view(user_id, camp, type) do
    camps = UserServer.store_user_camp_view(user_id, camp, type)
    camps
    |> Enum.take(200)
    |> update_user_data_with_recent_camps(user_id, type)
  end
  defp get_recent_view_ids_from_data_base(user_id) do
    user_id
    |> query_recent_views_user_data
    |> Repo.all
    |> List.first
  end
  defp get_recent_camps_ids_from_data_base(user_id) do
    recent_camp_ids =
      user_id
      |> query_recent_camps_user_data
      |> Repo.all
      |> List.first
    case recent_camp_ids do
      [] ->
        recent_camp_ids = Repo.all(query_recent_camps(user_id))
        spawn(__MODULE__, :update_user_data_with_recent_camps, [recent_camp_ids, user_id, :joined])
        recent_camp_ids
      recent_camp_ids ->
        recent_camp_ids
    end
  end

  defp get_camps_ids_from_data_base(user_id, :joined) do
    Repo.all(query_recent_camps(user_id))
  end
  defp get_camps_ids_from_data_base(user_id, :created) do
    Repo.all(query_camps_by_created(user_id))
  end

  defp query_camps_from_ids(ids, user_id) do
    from camp in Camp,
      where: camp.id in ^ids,
      join: rating in Rating,
      where: rating.user_id == ^user_id,
      where: rating.camp_id == camp.id,
      select: %{id: camp.id, current_content: camp.current_content, created: camp.inserted_at, joined: rating.inserted_at}
  end

  defp query_recent_camps_user_data(user_id) do
    from data in UserData,
      where: data.user_id == ^user_id,
      select: data.recent_camps
  end

  defp query_recent_views_user_data(user_id) do
    from data in UserData,
      where: data.user_id == ^user_id,
      select: data.recent_views
  end

  defp query_camps_by_created(user_id) do
    from rating in Rating,
      where: rating.user_id == ^user_id,
      where: rating.value in [4,5],
      join: camp in Camp,
      where: camp.id == rating.camp_id,
      order_by: camp.inserted_at,
      limit: 200,
      select: camp.id
  end

  defp query_recent_camps(user_id) do
    from rating in Rating,
      where: rating.user_id == ^user_id,
      where: rating.value in [4,5],
      order_by: rating.inserted_at,
      limit: 200,
      select: rating.camp_id
  end

  def update_user_data_with_recent_camps(camps, user_id, :joined) do
    Accounts.update_user_data(user_id, %{recent_camps: camps})
  end
  def update_user_data_with_recent_camps(camps, user_id, :unjoined) do
    Accounts.update_user_data(user_id, %{recent_views: camps})
  end
end
