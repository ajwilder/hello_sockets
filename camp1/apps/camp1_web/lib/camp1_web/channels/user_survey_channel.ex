defmodule Camp1Web.UserSurveyChannel do
  use Camp1Web, :channel

  def join("user_survey_channel", _params, socket) do
    {:ok, socket}
  end

end
