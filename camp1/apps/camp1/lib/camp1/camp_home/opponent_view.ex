defmodule Camp1.CampHome.OpponentView do

  import Ecto.Query, warn: false
  alias Camp1.Public.{CampOpponentRelationship}
  alias Camp1.CampServer
  alias Camp1.CampHome.OpponentViewServer
  alias Camp1.Repo

  def get_opponent_view(camp_id, opponent_id) do
    process_name = :"OpponentView-#{camp_id}:#{opponent_id}"
    process = Process.whereis(process_name)
    case process do
      nil ->
        opponent_view = create_opponent_view(camp_id, opponent_id)
        {:ok, _process} =
          OpponentViewServer.start(%{
            name: process_name,
            opponent_view: opponent_view,
            camp_id: camp_id,
            opponent_id: opponent_id
          })
        opponent_view
      process ->
        {:ok, opponent_view} = GenServer.call(process, :get_opponent_view)
        opponent_view
    end
  end

  def create_opponent_view(camp_id, opponent_id) do
    camp_reasons = CampServer.get_reasons(camp_id, 0)
    opponent_reasons = CampServer.get_reasons(opponent_id, 0)
    relationships =
      get_reason_relationships(
        Enum.map(camp_reasons, &(&1.id)),
        Enum.map(opponent_reasons, &(&1.id))
      )
      |> reason_relationship_list_to_map()

    camp_basic_data = CampServer.get_basic_data(camp_id)
    opponent_basic_data = CampServer.get_basic_data(opponent_id)
    opponent_view = assemble_opponent_view(camp_reasons, opponent_reasons, relationships)
    [{camp_basic_data, opponent_basic_data} | opponent_view]
  end

  def get_reason_relationships(camp_reason_ids, opponent_reasons_ids) do
    query_reason_relationship(camp_reason_ids, opponent_reasons_ids)
    |> Repo.all()
  end

  def query_reason_relationship(camp_reason_ids, opponent_reasons_ids) do
    from rel in CampOpponentRelationship,
      where: rel.camp_id in ^camp_reason_ids,
      where: rel.opponent_id in ^opponent_reasons_ids,
      select: [rel.camp_id, rel.opponent_id]
  end

  def reason_relationship_list_to_map(results) do
    Enum.reduce(results, %{},
      fn list, map ->
        Map.put(map, Enum.at(list, 0), Enum.at(list, 1))
      end)
  end


  # assemble_opponent_view parses the reason lists and aligns reasons that oppose each other.  Outputs a list that is meant to be iterated over to form the html elements of the opponent view.
  def assemble_opponent_view(camp_reasons, opponent_reasons, relationships, processed \\ [], assembled_list \\ [])
  def assemble_opponent_view([], _opponent_reasons, _relationships, _processed, assembled_list) do
    Enum.reverse assembled_list
  end
  def assemble_opponent_view([camp_reason | camp_reasons], all_opponent_reasons = [opponent_reason | opponent_reasons], relationships, processed, assembled_list) do
    opposed_camp_ids = Map.keys(relationships)
    opposing_ids = Enum.map(opposed_camp_ids, fn id -> relationships[id] end)
    cond do
      Enum.member?(opposed_camp_ids, camp_reason[:id]) ->  # check if reason has opponent
        # Get all reasons that oppose this camp_reason
        opposing_reasons = Enum.filter(all_opponent_reasons, fn reason ->
          reason[:id] == relationships[camp_reason[:id]]
        end)
        # add all oppsosing reasons to assembled list as counter to camp reason
        assembled_list = Enum.reduce(opposing_reasons, assembled_list,
        fn opposing_reason, list ->
          [{opposing_reason, camp_reason} | list]
        end)

        # mark eash opposing reason as processed so won't be added again
        processed = Enum.reduce(opposing_reasons, processed,
        fn opposing_reason, list ->
          [opposing_reason[:id] | list]
        end)
        assemble_opponent_view(camp_reasons, all_opponent_reasons, relationships, processed, assembled_list)
      true ->
        cond do
          Enum.member?(processed, opponent_reason[:id]) ->
            # do not add already processed opponent_reason to assembled_list
            assembled_list = [{nil, camp_reason} | assembled_list]
            assemble_opponent_view(camp_reasons, opponent_reasons, relationships, processed, assembled_list)
          Enum.member?(opposing_ids, opponent_reason[:id]) ->
            # do not add already processed opponent_reason to assembled_list
            assembled_list = [{opponent_reason, nil} | assembled_list]
            assembled_list = [{nil, camp_reason} | assembled_list]
            assemble_opponent_view(camp_reasons, opponent_reasons ++ [opponent_reason], relationships, processed, assembled_list)
          true ->
            # add both unoppposed reasons to assembled list.
            assembled_list = [{opponent_reason, nil} | assembled_list]
            assembled_list = [{nil, camp_reason} | assembled_list]
            assemble_opponent_view(camp_reasons, opponent_reasons, relationships, processed, assembled_list)
        end
    end
  end
end
