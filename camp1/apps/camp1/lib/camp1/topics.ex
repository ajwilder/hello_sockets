defmodule Camp1.Topics do
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Camp1.Topics.Subject
  alias Camp1.Public.Camp


  def list_subjects do
    Repo.all(Subject)
  end

  def get_subject_ids_ordered_by_camp_count do
    # # This is cached and can be accessed by TopicsServer

    Repo.all(query_top_subjects())
    |> Enum.reduce([], fn subject_id, list ->
      count =
        List.first(Repo.all(query_camp_count_for_subject_children(subject_id))) +
        List.first(Repo.all(query_camp_count_for_subject(subject_id)))
      [{subject_id, count} | list]
    end)
    |> Enum.sort_by(&(0 - (elem(&1, 1))))
    |> Enum.map(fn tup -> elem(tup, 0) end)
  end

  def get_top_subject_names do
    # # This is cached and can be accessed by TopicsServer
    Repo.all(query_top_subjects_with_name())
    |> Enum.reduce(%{}, fn {id, name}, map ->
      Map.put(map, id, name)
    end)
  end

  def get_subject!(id), do: Repo.get!(Subject, id)
  def get_subject(id), do: Repo.get(Subject, id)
  def get_subject_by(attrs) do
    Repo.get_by(Subject, attrs)
  end

  def create_subject(attrs \\ %{}) do
    %Subject{}
    |> Subject.changeset(attrs)
    |> Repo.insert()
  end

  def update_subject(%Subject{} = subject, attrs) do
    subject
    |> Subject.changeset(attrs)
    |> Repo.update()
  end

  def delete_subject(%Subject{} = subject) do
    Repo.delete(subject)
  end

  def change_subject(%Subject{} = subject, attrs \\ %{}) do
    Subject.changeset(subject, attrs)
  end

  # Not private, used by UserCompare
  def query_subject_for_children(subject_id) do
    from subject in Subject,
      where: subject.parent_id == ^subject_id,
      select: subject.id
  end

  defp query_camp_count_for_subject_children(subject_id) do
    from camps in Camp,
      where: camps.subject_id in subquery(query_subject_for_children(subject_id)),
      select: count(camps.id)
  end

  defp query_camp_count_for_subject(subject_id) do
    from camps in Camp,
      where: camps.subject_id == ^subject_id,
      select: count(camps.id)
  end

  defp query_top_subjects() do
    from subject in Subject,
      where: is_nil(subject.parent_id),
      select: subject.id
  end

  defp query_top_subjects_with_name() do
    from subject in Subject,
      where: is_nil(subject.parent_id),
      select: {subject.id, subject.content}

  end

end
