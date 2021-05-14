defmodule Camp1.Manifesto do
  import Ecto.{Query}, warn: false
  alias Camp1.{Repo, UserServer}
  alias Camp1.Manifesto.{Record, ManifestoVote}

  def update_manifesto(id, attrs) do
    %Record{id: id}
    |> Record.changeset(attrs)
    |> Repo.update
  end

  def create_manifesto(attrs) do
    %Record{}
    |> Record.changeset(attrs)
    |> Repo.insert
  end

  def get_live_manifesto(camp_id) do
    query_live_manifesto(camp_id)
    |> Repo.all
    |> List.first
  end

  def get_manifesto(id) do
    Repo.get(Record, id)
  end

  def get_proposed(camp_id) do
    query_proposed(camp_id)
    |> Repo.all
    |> List.first
  end

  def get_version(manifesto_id) do
    query_version(manifesto_id)
    |> Repo.all
    |> List.first
  end

  def get_history(camp_id) do
    query_history(camp_id)
    |> Repo.all
  end

  def get_vote(user_id, manifesto_id) do
    query_vote(user_id, manifesto_id)
    |> Repo.all
    |> List.first
  end

  def get_camp_manifesto_votes(user_id, camp_id) do
    query_camp_votes(user_id, camp_id)
    |> Repo.all
    |> Enum.reduce(%{}, fn {record_id, vote_id, value}, map ->
      Map.put(map, record_id, {vote_id, value})
    end)
  end

  def create_vote(attrs) do
    %ManifestoVote{}
    |> ManifestoVote.changeset(attrs)
    |> Repo.insert
  end

  def update_vote(user_id, camp_id, manifesto_id, new_value, {vote_id, old_value}) when old_value == new_value do
    %ManifestoVote{id: vote_id}
    |> ManifestoVote.changeset(%{value: 0})
    |> Repo.update

    UserServer.put_manifesto_vote(user_id, camp_id, manifesto_id, {vote_id, 0})
  end
  def update_vote(user_id, camp_id, manifesto_id, new_value, {vote_id, _old_value}) do
    %ManifestoVote{id: vote_id}
    |> ManifestoVote.changeset(%{value: new_value})
    |> Repo.update

    UserServer.put_manifesto_vote(user_id, camp_id, manifesto_id, {vote_id, new_value})
  end

  # queries
  defp query_live_manifesto(camp_id) do
    from record in Record,
      where: record.camp_id == ^camp_id,
      where: record.status == :live,
      select: %{
        content: record.content,
        id: record.id,
        previous_id: record.previous_id,
        inserted_at: record.inserted_at,
        approved_at: record.approved_at
      }
  end

  defp query_proposed(camp_id) do
    from record in Record,
      where: record.camp_id == ^camp_id,
      where: record.status == :proposed,
      select: %{
        content: record.content,
        id: record.id,
        inserted_at: record.inserted_at,
      }
  end

  defp query_history(camp_id) do
    from record in Record,
      where: record.camp_id == ^camp_id,
      where: record.status == :old,
      order_by: record.inserted_at,
      select: %{
        id: record.id,
        approved_at: record.approved_at
      }
  end

  defp query_version(manifesto_id) do
    from record in Record,
      where: record.id == ^manifesto_id,
      select: record.content
  end

  defp query_vote(user_id, manifesto_id) do
    from vote in ManifestoVote,
      where: vote.user_id == ^user_id,
      where: vote.record_id == ^manifesto_id,
      select: {vote.id, vote.value}
  end

  defp query_camp_votes(user_id, camp_id) do
    from vote in ManifestoVote,
      where: vote.user_id == ^user_id,
      join: record in Record,
      where: record.camp_id == ^camp_id,
      select: {vote.record_id, vote.id, vote.value}

  end

end
