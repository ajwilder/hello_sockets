defmodule Camp1Web.SurveyController do
  use Camp1Web, :controller
  alias Camp1.Public
  alias Camp1.Survey
  def guest_results(conn, _params) do
    # Development Only
    topics =
      Enum.map(1..10, fn _i ->
        id = Enum.random(10..256)
        topic = Public.get_camp!(id)
        %{
          content: topic.current_content,
          id: id ,
          like_minded: Enum.random(10..400),
          total_surveyed: Enum.random(800..2000),
          rating: Enum.random(0..5),
          type: topic.type
        }
      end)
    conn
    |> assign(:dev, true)
    |> assign(:topics, topics)
    |> put_layout("guest.html")
    |> render("guest_results.html")
  end

  def guest_survey(conn, _params) do
    guest_survey_data = Survey.get_initial_camps()
    case guest_survey_data do
      [] ->
        conn
        |> redirect(to: "/")
      guest_survey_data ->
        conn
        |> put_layout("guest.html")
        |> assign(:channel, :survey)
        |> assign(:guest_survey, guest_survey_data)
        |> put_view(Camp1Web.SurveyView)
        |> render("guest_survey.html")
    end
  end

  def home_results(conn, _params) do
    conn
    |> put_layout("user.html")
    |> render("home_results.html")
  end
end
