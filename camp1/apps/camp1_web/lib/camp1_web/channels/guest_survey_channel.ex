defmodule Camp1Web.GuestSurveyChannel do
  use Camp1Web, :channel
  alias Camp1.{Survey}
  alias Camp1Web.{SurveyView}

  def join("guest_survey_channel", _params, socket) do
    socket =
      socket
      |> assign(:rating_prqs, [])
      |> assign(:ratings, [])
      |> assign(:responses, [])
      |> assign(:passes, [])
      |> assign(:unknowns, [])
    {:ok, socket}
  end

  def handle_in("new_rating", params, socket) do
    socket
      = socket
      |> store_rating_in_socket(params)
      |> get_prq(params)
      |> get_next_html_and_respond()
  end

  def handle_in("combine_camps", params, socket) do
    reply_to_combine_camps(params, socket)
  end

  defp store_rating_in_socket(socket, %{"id" => id, "rating" => rating}) do
    socket =
      socket
      |> assign(:responses, [{id, rating}|socket.assigns[:responses]])
    case rating do
      0 ->
        socket
        |> assign(:last_rating, :pass)
        |> assign(:passes, [{id, rating}|socket.assigns[:passes]])
      6 ->
        socket
        |> assign(:last_rating, :unknown)
        |> assign(:unknowns, [{id, rating}|socket.assigns[:unknowns]])
      _ ->
        socket
        |> assign(:last_rating, :rating)
        |> assign(:ratings, [{id, rating}|socket.assigns[:ratings]])
    end
  end

  def get_prq(socket, %{"rating" => 0}) do
    socket
  end

  def get_prq(socket, %{"type" => type, "content" => content, "id" => id, "rating" => rating}) do
    prq =
      Survey.get_camp_rating_stats([{id, rating}])
      |> Map.put(:content, content)
      |> Map.put(:rating, rating)
      |> Map.put(:type, String.to_atom(type))
    rating_prqs = [prq | socket.assigns[:rating_prqs]]
    assign(socket, :rating_prqs, rating_prqs)
  end

  def get_next_html_and_respond(socket) do
    case length(socket.assigns[:ratings]) do
      10 ->
        send_results(socket)
      _ ->
        next_camp = Survey.get_additional_camp(socket.assigns[:responses], socket.assigns[:next_id])
        socket = assign(socket, :next_id, next_camp[:camp_id])
        next_html =
          Phoenix.View.render_to_string(SurveyView, "_survey_item.html", %{camp: next_camp, i: "next"})
        {:reply, {:ok, %{next_html: next_html}}, socket}
    end
  end


  defp send_results(socket) do
    title_html =
      Phoenix.View.render_to_string(SurveyView, "guest_results.html", %{conn: false })
    results_html =
      Phoenix.View.render_to_string(
      SurveyView,
      "_survey_results.html",
      %{topics: socket.assigns[:rating_prqs]}
      )
    payload = %{result: :done, title_html: title_html, results_html: results_html}
    {:reply, {:ok, payload}, socket}
  end

  defp reply_to_combine_camps([[drag_id, drag_rating],[target_id, target_rating]], socket) do
    prq = Survey.get_camp_rating_stats([{drag_id, drag_rating}, {target_id, target_rating}])
    {:reply, {:ok, %{prq: prq}}, socket}
  end

end
