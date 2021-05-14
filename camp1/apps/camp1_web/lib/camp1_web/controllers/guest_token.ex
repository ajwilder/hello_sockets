defmodule Camp1Web.GuestToken do
  import Phoenix.Controller
  alias RumblWeb.Router.Helpers, as: Routes
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    guest_token = get_session(conn, :guest_token)
    cond do
      guest_token ->
        conn
        |> put_guest_token_to_conn(guest_token)
      true ->
        conn
        |> put_guest_token_to_session()
    end

  end

  def put_guest_token_to_conn(conn, guest_token) do
    token = Phoenix.Token.sign(conn, "dc_0TaVGp2Ar", guest_token)
    conn
    |> assign(:guest_token, token)
  end

  def put_guest_token_to_session(conn) do
    token = generate_guest_session_token()
    conn
    |> put_session(:guest_token, token)
  end

  defp generate_guest_session_token do
    :crypto.strong_rand_bytes(16)
  end


end
