defmodule Camp1Web.GuestController do
  use Camp1Web, :controller

  def guest_home(conn, _params) do
    conn
    |> put_layout("guest.html")
    |> render("guest_home.html")
  end

end
