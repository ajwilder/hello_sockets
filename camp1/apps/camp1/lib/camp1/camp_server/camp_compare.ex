defmodule Camp1.CampServer.CampCompare do
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Camp1.Reactions.Rating
  alias Camp1.UserServer
  # alias Camp1.Reputation
  # alias Camp1.Topics
  alias Camp1.Public.Camp
  # alias Camp1.Topics.Subject

  def create_camp_compare(_camp_id) do
    # creates map of camp member ratings
    :ok
  end

  def create_camp_compare_for_subject(_user_id, _subject_id) do
    # creates map of camp member ratings in a subject
    :ok
  end

  def create_agreement_map_with_minimum_member_overlap(camp_id, minimum_member_overlap) do
    # This does not query user_data so is not utilizing userServer, but can limit the size of this agreement map for large camps.
    # The minimum_member_overlap should be adjusted for camp size. How this is adjusted will depend on how people actually use the app

    query_related_camps_with_count_and_top_subject_id(camp_id)
    |> Repo.all
    |> Enum.reduce(%{}, fn {related_camp, member_overlap, subject_id}, map ->
      if member_overlap > minimum_member_overlap do
        subject_map = map[subject_id]
        case subject_map do
          nil ->
            subject_map = Map.put(%{}, related_camp, %{
              a: List.first(Repo.all(query_user_agreement_for_related_camps(camp_id, related_camp))),
              d: List.first(Repo.all(query_user_disagreement_for_related_camps(camp_id, related_camp))),
              m: member_overlap
              })

            Map.put(map, subject_id, subject_map)
          subject_map ->
            subject_map = Map.put(subject_map, related_camp, %{
              a: List.first(Repo.all(query_user_agreement_for_related_camps(camp_id, related_camp))),
              d: List.first(Repo.all(query_user_disagreement_for_related_camps(camp_id, related_camp))),
              m: member_overlap
              })
            Map.put(map, subject_id, subject_map)
        end
      else
        map
      end
    end)
  end

  def create_agreement_map_from_user_compare_maps(camp_id) do
    # cycles through camp members to get all camps that members have agreed to.
    #  This is very intensive to pull directly from database
    get_camp_members_from_db(camp_id)
    |> Enum.reduce(%{}, fn user_id, camp_compare_map ->
      add_user_data_to_camp_compare_map(user_id, camp_compare_map)
    end)
  end

  defp add_user_data_to_camp_compare_map(user_id, camp_compare_map) do
    # takes a map and adds user data to it
    user_agreement_map = UserServer.get_user_agreement_map(user_id)
    user_disagreement_map = UserServer.get_user_disagreement_map(user_id)
    Map.keys(user_agreement_map)
    |> Enum.reduce(camp_compare_map, fn key, map ->
      map =
        Map.update(map, key, %{}, fn a -> a end)

      new_subject_data = add_agreement_list_to_map(user_agreement_map[key], map[key])
      new_subject_data = add_disagreement_list_to_map(user_disagreement_map[key], new_subject_data)

      Map.put(map, key, new_subject_data)
    end)
  end

  defp add_agreement_list_to_map(agreement_list, subject_map) do
    agreement_list
    |> Enum.reduce(subject_map, fn camp_id, map ->
      Map.update(
        map,
        camp_id,
        %{agreements: 1, disagreements: 0},
        fn current_data = %{agreements: n} ->
          Map.put(current_data, :agreements, n+1)
        end)
    end)
  end

  defp add_disagreement_list_to_map(agreement_list, subject_map) do
    agreement_list
    |> Enum.reduce(subject_map, fn camp_id, map ->
      Map.update(
        map,
        camp_id,
        %{agreements: 0, disagreements: 1},
        fn current_data = %{disagreements: n} ->
          Map.put(current_data, :disagreements, n+1)
        end)
    end)
  end

  def get_camp_members_from_db(camp_id) do
    (from rate in Rating,
      where: rate.camp_id == ^camp_id,
      where: rate.value in [4,5],
      select: rate.user_id)
    |> Repo.all
  end


  def query_camp_members_from_db(camp_id) do
    from rate in Rating,
      where: rate.camp_id == ^camp_id,
      where: rate.value in [4,5],
      select: rate.user_id
  end

  def query_related_camps(camp_id) do
    from rate in Rating,
      where: rate.user_id in subquery(query_camp_members_from_db(camp_id)),
      where: rate.value in [4,5],
      distinct: true,
      select: rate.camp_id
  end

  def query_related_camps_with_count(camp_id) do
    from rate in Rating,
      where: rate.user_id in subquery(query_camp_members_from_db(camp_id)),
      where: rate.value in [4,5],
      group_by: rate.camp_id,
      select: {rate.camp_id, count(rate.camp_id)}
  end

  def query_related_camps_with_count_and_top_subject_id(camp_id) do
    from rate in Rating,
      where: rate.user_id in subquery(query_camp_members_from_db(camp_id)),
      where: rate.value in [4,5],
      join: camp in Camp,
      where: camp.id == rate.camp_id,
      group_by: [rate.camp_id, camp.top_subject_id],
      select: {rate.camp_id, count(rate.camp_id), camp.top_subject_id}
  end

  def query_user_agreement_for_related_camps(camp_id, related_camp_id) do
    from rate in Rating,
      where: rate.user_id in subquery(query_camp_members_from_db(camp_id)),
      where: rate.value in [4,5],
      where: rate.camp_id == ^related_camp_id,
      select: count(rate.id)
  end


  def query_user_disagreement_for_related_camps(camp_id, related_camp_id) do
    from rate in Rating,
      where: rate.user_id in subquery(query_camp_members_from_db(camp_id)),
      where: rate.value in [1,2],
      where: rate.camp_id == ^related_camp_id,
      select: count(rate.id)
  end
end
