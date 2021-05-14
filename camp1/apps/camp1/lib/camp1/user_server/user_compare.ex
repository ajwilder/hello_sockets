defmodule Camp1.UserServer.UserCompare do
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Camp1.Reactions.Rating
  # alias Camp1.Reputation
  alias Camp1.Topics
  alias Camp1.Public.Camp
  alias Camp1.UserServer
  alias Camp1.CampServer


  def compare_user_to_camp(user_id, camp_id) do
    agree_user = UserServer.get_user_agreement_map(user_id)
    agree_camp = CampServer.get_camp_agreement_map(camp_id)
    disagree_user = UserServer.get_user_disagreement_map(user_id)
    disagree_camp = CampServer.get_camp_disagreement_map(camp_id)
    create_user_camp_compare(agree_user, agree_camp, disagree_user, disagree_camp)
  end

  defp create_user_camp_compare(_, nil, _, nil) do
    :calculating
  end

  defp create_user_camp_compare(agree_user, agree_camp, disagree_user, disagree_camp) do
    Map.keys(agree_user)
    |> Enum.map(fn key ->
      agrees =
        (length(agree_user[key]) - length(agree_user[key] -- agree_camp[key])) + (length(disagree_user[key]) - length(disagree_user[key] -- disagree_camp[key]))
      disagrees =
        (length(agree_user[key]) - length(agree_user[key] -- disagree_camp[key])) + (length(disagree_user[key]) - length(disagree_user[key] -- agree_camp[key]))
      total = agrees + disagrees
      case total do
        0 ->
          %{
            key => %{
              agree: "no data",
              agree_count: agrees,
              disagree: "no data",
              disagree_count: disagrees,
              total_count: agrees + disagrees
            }
          }
        _ ->
          %{
            key => %{
              agree: agrees / total,
              agree_count: agrees,
              disagree: disagrees / total,
              disagree_count: disagrees,
              total_count: agrees + disagrees
            }
          }
      end
    end)
  end


  def compare_two_users(user_id1, user_id2) do
    agree1 = UserServer.get_user_agreement_map(user_id1)
    agree2 = UserServer.get_user_agreement_map(user_id2)
    disagree1 = UserServer.get_user_disagreement_map(user_id1)
    disagree2 = UserServer.get_user_disagreement_map(user_id2)
    Map.keys(agree1)
    |> Enum.map(fn key ->
      agrees =
        (length(agree1[key]) - length(agree1[key] -- agree2[key])) +
        (length(disagree1[key]) - length(disagree1[key] -- disagree2[key]))
      disagrees =
        (length(agree1[key]) - length(agree1[key] -- disagree2[key])) +
        (length(disagree1[key]) - length(disagree1[key] -- agree2[key]))
      total = agrees + disagrees
      case total do
        0 ->
          %{
            key => %{
              agree: "no data",
              agree_count: agrees,
              disagree: "no data",
              disagree_count: disagrees,
              total_count: agrees + disagrees
            }
          }
        _ ->
          %{
            key => %{
              agree: agrees / total,
              agree_count: agrees,
              disagree: disagrees / total,
              disagree_count: disagrees,
              total_count: agrees + disagrees
            }
          }
      end
    end)
  end

  def create_user_agreement_map(user_id) do
    # creates map of user camps by subject
    Topics.TopicsServer.get_subject_ids_ordered_by_camp_count
    |> Enum.reduce(%{}, fn subject_id, map ->
      Map.put(map, subject_id, get_user_camp_ids_by_subject(user_id, subject_id))
    end)
  end

  def create_user_disagreement_map(user_id) do
    # creates map of user camps by subject
    Topics.TopicsServer.get_subject_ids_ordered_by_camp_count
    |> Enum.reduce(%{}, fn subject_id, map ->
      Map.put(map, subject_id, get_user_opponent_ids_by_subject(user_id, subject_id))
    end)
  end

  def get_user_camp_ids(user_id) do
    q = from ratings in Rating,
      where: ratings.value in [4,5],
      where: ratings.user_id == ^user_id,
      select: ratings.camp_id
    Repo.all(q)
  end

  def get_user_camp_ids_by_subject(user_id, subject_id) do
    q = from ratings in Rating,
      where: ratings.value in [4,5],
      where: ratings.user_id == ^user_id,
      join: camps in Camp,
      where: camps.id == ratings.camp_id,
      where: camps.subject_id in subquery(Topics.query_subject_for_children(subject_id)),
      select: camps.id
    Repo.all(q)
  end

  def get_user_opponent_ids_by_subject(user_id, subject_id) do
    q = from ratings in Rating,
      where: ratings.value in [1,2],
      where: ratings.user_id == ^user_id,
      join: camps in Camp,
      where: camps.id == ratings.camp_id,
      where: camps.subject_id in subquery(Topics.query_subject_for_children(subject_id)),
      select: camps.id
    Repo.all(q)
  end
end
