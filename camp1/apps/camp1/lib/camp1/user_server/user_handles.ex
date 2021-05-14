defmodule Camp1.UserHome.UserHandles do
  alias Camp1.Accounts.{UserData}
  alias Camp1.UserServer
  import Ecto.Query, warn: false
  alias Camp1.Repo


  def get_default_user_handle(user_id) do
    UserServer.get_user_handle(user_id)
  end

  def get_default_user_handle_from_database(user_id) do
    query_user_handle_user_data(user_id)
    |> Repo.all
    |> List.first
  end

  defp query_user_handle_user_data(user_id) do
    from data in UserData,
      where: data.user_id == ^user_id,
      select: data.default_handle
  end

end
