defmodule Camp1.Topics.TopicsStash do
  use GenServer
  alias Camp1.Topics

  @update 6 * 60 * 60 * 1000

  def start do
    name = :"TopicsStash"
    {:ok, process} = GenServer.start(
      __MODULE__,
      %{
        top_subject_names: nil,
        subject_ids_ordered_by_camp_count: nil,
        },
      name: name
    )
    {:ok, process}
  end

  def init(stash) do
    :timer.send_after(@update, :update_data)
    {:ok, stash}
  end

  def handle_call(:get_top_subject_names, _from, stash = %{top_subject_names: top_subject_names}) do
    {:reply, {:ok, top_subject_names}, stash}
  end

  def handle_call(:get_subject_ids_ordered_by_camp_count, _from, stash = %{subject_ids_ordered_by_camp_count: subject_ids_ordered_by_camp_count}) do
    {:reply, {:ok, subject_ids_ordered_by_camp_count}, stash}
  end


  def handle_cast({:put_subject_ids_ordered_by_camp_count, sub_ids}, stash) do
    {:noreply, Map.put(stash, :subject_ids_ordered_by_camp_count, sub_ids)}
  end

  def handle_cast({:put_top_subject_names, sub_names_map}, stash) do
    {:noreply, Map.put(stash, :top_subject_names, sub_names_map)}
  end

  def handle_info(:update_data, stash) do
    stash =
      stash
      |> Map.put(:subject_ids_ordered_by_camp_count, Topics.get_subject_ids_ordered_by_camp_count())
      |> Map.put(:top_subject_names, Topics.get_top_subject_names())
    {:noreply, stash}
  end

end
