defmodule Camp1.Reputation do
  alias Camp1.Reputation.{Contribution, Handle}
  alias Camp1.Repo
  import Ecto.Query, warn: false

  def get_user_reputation(_user_id, _camp_id) do
    # calculate based on user's contributions to a camp
    :ok

  end

  def get_handle(user_id, camp_id) do
    query_handle(user_id, camp_id)
    |> Repo.all
    |> List.first
  end

  def create_contribution(attrs) do
    # create record of users contribution to a camp.
    # contribution is stored as an integer
    # +100 originator, +10 subcamp originator, +1 participation in successful edit or subcamp origination
    # Also need to factor in message board, image board, and private messages
    # ^ this is where negative reputation can come into play
    %Contribution{}
    |> Contribution.changeset(attrs)
    |> Repo.insert
  end

  def create_handle(attrs) do
    %Handle{}
    |> Handle.changeset(attrs)
    |> Repo.insert()
  end

  defp query_handle(user_id, camp_id) do
    from handle in Handle,
      where: handle.user_id == ^user_id,
      where: handle.camp_id == ^camp_id,
      select: handle.value
  end
end
