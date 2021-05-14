defmodule Camp1.CampServer.CampCompareStash do
  use GenServer
  alias Camp1.CampServer.CampCompare
  alias Camp1.Repo
  import Ecto.Query, warn: false
  alias Camp1.Public.CampData
  alias Camp1.Public
  @timeout 48 * 60 * 60 * 1000
  @hibernate 12 * 60 * 60 * 1000
  @max_byte_size 250_000 # max_byte_size prevents compare map from being too large
  @update 12 * 60 * 60 * 1000

  def start_link(%{name: name, camp_id: camp_id}) do
    minimum_overlap = get_minimum_overlap(camp_id)
    comparison_map = Public.get_camp_comparison_map(camp_id)
    GenServer.start_link(
      __MODULE__,
      %{
        camp_compare_raw_data: comparison_map,
        minimum_overlap: minimum_overlap,
        agreement_map: nil,
        disagreement_map: nil,
        camp_id: camp_id
      },
      name: name,
      hibernate_after: @hibernate
    )
  end

  defp minimize_compare_to_byte_size(compare, minimum_overlap) do
    byte_size = :erlang.external_size compare
    cond do
      byte_size > @max_byte_size ->
        minimum_overlap = minimum_overlap + 1
        new_compare =
          compare
          |> Map.keys
          |> Enum.reduce(%{}, fn subject_key, map ->
            Map.put(map, subject_key, filter_subject_camps_by_overlap(compare[subject_key], minimum_overlap))
          end)
        minimize_compare_to_byte_size(new_compare, minimum_overlap)
      true ->
        {compare, minimum_overlap}
    end
  end

  defp filter_subject_camps_by_overlap(subject_map, minimum_overlap) do
    subject_map
    |> Map.keys
    |> Enum.reduce(%{}, fn camp_id, map ->
      cond do
        subject_map[camp_id][:m] > minimum_overlap ->
          Map.put(map, camp_id, subject_map[camp_id])
        true ->
          map
      end
    end)
  end

  def calculate_agreement_maps(raw_compare_data) do
    {
      calculate_agreement_map(raw_compare_data, :a),
      calculate_agreement_map(raw_compare_data, :d),
    }
  end

  def calculate_agreement_map(raw_compare_data, type) do
    raw_compare_data
    |> Map.keys
    |> Enum.reduce(%{}, fn subject_key, map ->
      Map.put(map, subject_key, calculate_subject_agreements(raw_compare_data[subject_key], type))
    end)
  end

  def calculate_subject_agreements(subject_map, type) do
    other_type =
      [:a, :d] -- [type]
      |> List.first
    subject_map
    |> Map.keys
    |> Enum.reduce([], fn camp_id, list ->
      cond do
        subject_map[camp_id][type] > subject_map[camp_id][other_type] ->
          [camp_id | list]
        true ->
          list
      end
    end)
  end


  def get_minimum_overlap(camp_id) do
    (from data in CampData,
      where: data.camp_id == ^camp_id,
      select: data.minimum_overlap)
    |> Repo.all
    |> List.first
  end





  # GENSERVER CALLBACKS

  def init(stash = %{camp_compare_raw_data: comparison_map}) do
    cond do
      comparison_map == %{} ->
        :timer.send_after(1, :update_data)
      true ->
        :timer.send_after(1, :soft_update_data)
        :timer.send_after(@update, :update_data)
    end
    :timer.send_after(@timeout, :job_timeout)
    {:ok, stash}
  end

  def handle_call(:get_camp_compare_raw_data, _from, stash = %{camp_compare_raw_data: camp_compare_raw_data, minimum_overlap: minimum_overlap}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, %{camp_compare_raw_data: camp_compare_raw_data, minimum_overlap: minimum_overlap}}, stash}
  end

  def handle_call(:get_camp_disagreement_map, _from, stash = %{disagreement_map: disagreement_map}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, disagreement_map}, stash}
  end

  def handle_call(:get_camp_agreement_map, _from, stash = %{agreement_map: agreement_map}) do
    :timer.send_after(@timeout, :job_timeout)
    {:reply, {:ok, agreement_map}, stash}
  end

  def handle_info(:update_data, stash = %{camp_id: camp_id, minimum_overlap: minimum_overlap}) do
    :timer.send_after(@update, :update_data)
    Task.async(fn ->
      compare = CampCompare.create_agreement_map_with_minimum_member_overlap(camp_id, minimum_overlap)
      {compare, minimum_overlap} = minimize_compare_to_byte_size(compare, minimum_overlap)
      {agreement_map, disagreement_map} = calculate_agreement_maps(compare)
      %CampData{id: camp_id}
      |> Public.update_camp_data(%{minimum_overlap: minimum_overlap, comparison_map: compare})
        stash
        |> Map.put(:camp_compare_raw_data, compare)
        |> Map.put(:minimum_overlap, minimum_overlap)
        |> Map.put(:agreement_map, agreement_map)
        |> Map.put(:disagreement_map, disagreement_map)
    end)
    {:noreply, stash}
  end

  def handle_info(:soft_update_data, stash = %{camp_compare_raw_data: compare}) do
    {agreement_map, disagreement_map} = calculate_agreement_maps(compare)
    stash
      = stash
      |> Map.put(:agreement_map, agreement_map)
      |> Map.put(:disagreement_map, disagreement_map)
    {:noreply, stash}
  end

  def handle_info(:job_timeout, state) do
    {:stop, :normal, state}
  end

  def handle_info({_task, new_stash}, _stash) do
    {:noreply, new_stash}
  end

  def handle_info(_, state), do: {:noreply, state}
end
