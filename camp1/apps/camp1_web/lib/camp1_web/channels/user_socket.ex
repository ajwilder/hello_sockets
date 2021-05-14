defmodule Camp1Web.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "user_home_channel", Camp1Web.UserHomeChannel
  channel "user_survey_channel", Camp1Web.UserSurveyChannel
  channel "user_camp_channel:*", Camp1Web.UserCampChannel
  channel "user_rt_channel:*", Camp1Web.UserRTChannel
  channel "private_chat_channel:*", Camp1Web.PrivateChatChannel
  channel "chat_room_channel:*", Camp1Web.ChatRoomChannel

  @max_age 2 * 7 * 24 * 60 * 60
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(
      "kjoy3o1zeidquwy1398juxzldjlksahdk3",
      "ngj2zRo0fttl",
      token,
      max_age: @max_age
    ) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}
      {:error, _reason} ->
        :error
    end
  end

  @impl true
  def id(_socket), do: nil
end
