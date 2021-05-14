defmodule Camp1.Topics.TopicsServer do
  alias Camp1.Topics.TopicsStash
  alias Camp1.Topics

  def get_subject_ids_ordered_by_camp_count do
    process = get_topics_server_process()
    {:ok, subject_ids} = GenServer.call(process, :get_subject_ids_ordered_by_camp_count)
    case subject_ids do
      nil ->
        subject_ids = Topics.get_subject_ids_ordered_by_camp_count()
        put_subject_ids_ordered_by_camp_count(process, subject_ids)
        subject_ids
      subject_ids ->
        subject_ids
    end
  end

  def get_top_subject_names do
    process = get_topics_server_process()
    {:ok, subject_names_map} = GenServer.call(process, :get_top_subject_names)
    case subject_names_map do
      nil ->
        subject_names_map = Topics.get_top_subject_names()
        put_top_subject_names(process, subject_names_map)
        subject_names_map
      subject_names_map ->
        subject_names_map
    end

  end

  defp put_subject_ids_ordered_by_camp_count(process, sub_ids) do
    GenServer.cast(process, {:put_subject_ids_ordered_by_camp_count, sub_ids})
  end

  defp put_top_subject_names(process, sub_names_map) do
    GenServer.cast(process, {:put_top_subject_names, sub_names_map})
  end

  defp get_topics_server_process() do
    process = Process.whereis(:"TopicsStash")
    case process do
      nil ->
        {:ok, process} = TopicsStash.start()
        process
      process ->
        process
    end
  end
end
