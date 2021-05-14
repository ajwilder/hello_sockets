defmodule Camp1Web.GuestSocket do
  use Phoenix.Socket

  channel "guest_survey_channel", Camp1Web.GuestSurveyChannel
  channel "guest_camp_channel:*", Camp1Web.GuestCampChannel

  @max_age 2 * 7 * 24 * 60 * 60
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(
      socket,
      "dc_0TaVGp2Ar",
      token,
      max_age: @max_age
    ) do
      {:ok, guest_session_token} ->
        {:ok, assign(socket, :guest_session_token, guest_session_token)}
      {:error, _reason} ->
        :error
    end
  end

  @impl true
  def id(_socket), do: nil

end
