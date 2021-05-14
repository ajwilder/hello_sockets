defmodule Camp1.SeedUsers do
  alias Camp1.Accounts
  import Ecto.Query, warn: false
  alias Camp1.Repo
  alias Camp1.Reactions.Rating
  alias Camp1.Reputation

  def seed_n_users(n) do
    0..n
    |> Enum.each(&seed_user(&1))
  end

  defp seed_user(n) do
    map = %{
      email: "#{FakerElixir.Name.first_name}#{n}@example.com",
      password: "111111",
    }
    Accounts.register_user(map)
  end

  def seed_handles() do
    Accounts.list_users
    |> Enum.each(fn user ->
      Accounts.update_user_data(user.id, %{default_handle: FakerElixir.Name.first_name})
      get_user_camps(user.id)
      |> Enum.each(fn camp_id ->
        Reputation.create_handle(%{
          user_id: user.id,
          camp_id: camp_id,
          value: FakerElixir.Name.first_name
          })
      end)

    end)
  end

  def seed_contributions do
    users = Accounts.list_users
    users
    |> Enum.each(fn user ->
      get_user_camps(user.id)
      |> Enum.each(fn camp_id ->
        Reputation.create_contribution(%{
          camp_id: camp_id,
          user_id: user.id,
          value: Enum.random(0..100)
          })
      end)
    end)
  end

  def seed_contacts do
    users = Accounts.list_users
    user_ids = Enum.map(users, &(&1.id))
    users
    |> Enum.each(fn user ->
      ids = user_ids -- [user.id]
      ids = Enum.take_random(ids, 10)
      ids
      |> Enum.each(fn id ->
        Accounts.create_contact(
          %{
            user_id: user.id,
            contact_id: id,
            user_name: FakerElixir.Name.first_name,
            contact_name: FakerElixir.Name.first_name
          }
        )
      end)
    end)
  end

  def seed_contacts(user_id) do
    users = Accounts.list_users
    user_ids = Enum.map(users, &(&1.id))
    ids = user_ids -- [user_id]
    ids = Enum.take_random(ids, 10)
    ids
    |> Enum.each(fn id ->
      Accounts.create_contact(
        %{
          user_id: user_id,
          contact_id: id,
          user_name: FakerElixir.Name.first_name,
          contact_name: FakerElixir.Name.first_name
        }
      )
    end)
  end

  defp get_user_camps(user_id) do
    q = from ratings in Rating,
      where: ratings.value in [4,5],
      where: ratings.user_id == ^user_id,
      select: ratings.camp_id
    Repo.all(q)

  end
end
