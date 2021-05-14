defmodule Camp1.SeedCamps do
  alias Camp1.Public.{Camp, CampOpponentRelationship, CampChildRelationship, CampData}
  alias Camp1.Public
  import Ecto.Query, warn: false
  alias Camp1.Repo

  def add_n_reasons_to_existing_camps(n) do
    camps = Repo.all(query_live_camps())
    camps
      |> Enum.each(fn camp ->
        Enum.each(1..n, fn _i ->
          create_fake_reason_camp(camp)
        end)
      end)
  end

  def add_n_children_to_existing_camps(n) do
    camps = Repo.all(query_live_camps())
    camps
      |> Enum.each(fn camp ->
        Enum.each(1..n, fn _i ->
          create_fake_child_camp(camp)
        end)
      end)
  end

  def add_some_fake_opponents(n) do
    camps = Repo.all(query_live_camps())
    camps
      |> Enum.each(fn camp ->
        i = :rand.uniform
        cond do
          i > 0.5 ->
            Enum.each(1..n, fn _i ->
              create_fake_opponent_camp(camp)
            end)
          true ->
            :ok
        end
      end)
  end

  defp query_live_camps() do
    from Camp, where: [status: :live]
  end

  defp create_fake_opponent_camp(parent) do
    fake_camp = %{
      type: "notion",
      subject_id: parent.subject_id,
      status: "live",
      original_content: FakerElixir.Lorem.sentence,
    }
    {:ok, %{camp: camp}}= Public.create_camp_with_opponent(fake_camp, parent.id)
    {:ok, _relationship} = Public.create_camp_opponent_relationship(
      %{
        camp_id: parent.id,
        opponent_id: camp.id
      }
    )
  end

  defp create_fake_child_camp(parent) do
    fake_camp = %{
      type: "notion",
      subject_id: parent.subject_id,
      status: "live",
      original_content: FakerElixir.Lorem.sentence,
    }
    Public.create_camp_with_parent(fake_camp, :child, parent.id)
  end

  defp create_fake_reason_camp(parent) do
    fake_camp = %{
      type: "notion",
      subject_id: parent.subject_id,
      status: "live",
      original_content: FakerElixir.Lorem.sentence,
    }
    {:ok, %{camp: camp}} = Public.create_camp_with_parent(fake_camp, :reason, parent.id)
    i = :rand.uniform
    cond do
      i > 0.7 ->
        create_opponent_relationship_if_possible(camp.id, parent.id)
      true ->
        :ok
    end
  end

  defp create_opponent_relationship_if_possible(camp_id, parent_id) do
    opponent_id =
      parent_id
      |> query_for_appropriate_opponent
      |> Repo.all
      |> List.first
    Public.create_camp_opponent_relationship(%{
      camp_id: camp_id,
      opponent_id: opponent_id
      })
    Public.create_camp_opponent_relationship(%{
      camp_id: opponent_id,
      opponent_id: camp_id
      })
  end

  defp query_for_appropriate_opponent(parent_id) do
    from rel in CampOpponentRelationship,
      where: rel.camp_id == ^parent_id,
      join: child_rel in CampChildRelationship,
      where: child_rel.parent_id == rel.opponent_id,
      where: child_rel.type == :reason,
      limit: 1,
      select: child_rel.child_id

  end

end
