defmodule RumblTestWeb.PageController do
  use RumblTestWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
