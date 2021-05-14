defmodule Camp1.Survey.AdditionalCamps do
  import Ecto.Query, warn: false
  alias Camp1.Public.Camp
  alias Camp1.Repo

  def get_additional_camp(ratings, last_id) do
    camp_ids = ratings_to_ids_list(ratings, last_id)
    q = query_next_additional_camp(camp_ids)
    camp = List.first Repo.all(q)
    IO.inspect camp_ids
    IO.puts camp[:camp_id]
    camp
  end

  def query_next_additional_camp(camp_ids) do
    from camp in Camp,
      where: camp.id not in ^camp_ids,
      where: camp.type != :type,
      where: camp.status != :fake,
      join: relationships in "camp_opponent_relationships",
      where: relationships.camp_id == camp.id,
      join: opponents in Camp,
      where: opponents.id == relationships.opponent_id,
      join: subject in "subjects",
      where: subject.id == camp.subject_id,
      order_by: fragment("RANDOM()"),
      select: %{subject_id: subject.id, subject_content: subject.content, camp_id: camp.id, camp_content: camp.current_content, camp_type: camp.type, opposition_id: opponents.id, opposition_content: opponents.current_content, opposition_type: opponents.type},
      limit: 1
  end

  defp ratings_to_ids_list(ratings, last_id) do
    camp_ids =
      ratings
      |> Enum.map(fn ele -> elem(ele, 0) end)
    case last_id do
      nil ->
        camp_ids
      _ ->
        [last_id | camp_ids]
    end
  end

end
