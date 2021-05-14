defmodule Camp1.Survey.InitialCamps do
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Camp1.Public.Camp
  def get_initial_camps do
    camp_count = Repo.count("camps")
    random_values =
      Enum.map(0..120, fn _i ->
        Enum.random(1..camp_count)
      end)
    random_values
    |> Enum.uniq
    |> query_guest_survey_with_opposition_by_id_list()
    |> Repo.all
  end

  def query_guest_survey_by_id_list(id_list) do
    from camp in Camp,
      where: camp.id in ^id_list,
      where: camp.type != :type,
      join: subject in "subjects",
      where: subject.id == camp.subject_id,
      select: %{subject_id: subject.id, subject_content: subject.content, camp_id: camp.id, camp_content: camp.current_content, camp_type: camp.type}
  end

  defp query_guest_survey_with_opposition_by_id_list(id_list) do
    from camp in Camp,
      where: camp.id in ^id_list,
      where: camp.type != :type,
      where: camp.status != :fake,
      join: relationships in "camp_opponent_relationships",
      where: relationships.camp_id == camp.id,
      join: opponents in Camp,
      where: opponents.id == relationships.opponent_id,
      join: subject in "subjects",
      where: subject.id == camp.subject_id,
      select: %{subject_id: subject.id, subject_content: subject.content, camp_id: camp.id, camp_content: camp.current_content, camp_type: camp.type, opposition_id: opponents.id, opposition_content: opponents.current_content, opposition_type: opponents.type}
  end
end
