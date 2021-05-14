defmodule Camp1.Survey do
  alias Camp1.Public.CampRatingQueries
  alias Camp1.Survey.{CampRatings, InitialCamps, AdditionalCamps}



  defdelegate get_initial_camps(), to: InitialCamps

  defdelegate get_additional_camp(ratings, last_id), to: AdditionalCamps

  def get_camp_rating_stats(survey_data) do
    processed_data = process_data(survey_data)
    prq = get_results(processed_data)
    %{
      total_surveyed: prq[:total],
      like_minded: prq[processed_data[:final_rating]],
      id: processed_data[:final_id],
    }
  end

  defp process_data(list, processed_data \\ %{process_name: ""})
  defp process_data([{id,rating}|tail], %{process_name: ""}) do
    data =
      %{}
      |> Map.put(:process_name, "#{id}")
      |> Map.put(:final_rating, rating)
      |> Map.put(:final_id, id)
      |> Map.put(:ratings_list, [id])
    process_data(tail, data)
  end
  defp process_data([], data), do: data
  defp process_data([head = {id,rating}|tail], data) do
    data =
      data
      |> Map.put(:process_name, "{#{id},#{rating}}" <> data[:process_name] )
      |> Map.put(:ratings_list, [head | data[:ratings_list]])
    process_data(tail, data)
  end

  defp get_results(%{process_name: process_name, ratings_list: ratings_list}) do
    process_name = :"CampRatings-#{process_name}"
    process = Process.whereis(process_name)
    case process do
      nil ->
        prq = CampRatingQueries.get_camp_ratings_map(ratings_list)
        {:ok, _process} = CampRatings.start(%{name: process_name, prq: prq})
        prq
      process ->
        {:ok, prq} = GenServer.call(process, :get_prq)
        prq
    end
  end
end
