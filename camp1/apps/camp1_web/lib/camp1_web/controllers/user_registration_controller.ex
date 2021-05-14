defmodule Camp1Web.UserRegistrationController do
  use Camp1Web, :controller

  alias Camp1.Accounts
  alias Camp1.Accounts.User
  alias Camp1Web.UserAuth

  plug :put_layout, "guest.html"

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params, conn.cookies["campRatings"]) do
      {:ok, %{user: user}} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :confirm, &1)
          )

        conn
        |> put_flash(:info, "Welcome to Camps.")
        |> UserAuth.log_in_user(user)
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :confirm, &1)
          )

        conn
        |> put_flash(:info, "Welcome to Camps.")
        |> UserAuth.log_in_user(user)
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect changeset
        render(conn, "new.html", changeset: changeset)
    end
  end
end
