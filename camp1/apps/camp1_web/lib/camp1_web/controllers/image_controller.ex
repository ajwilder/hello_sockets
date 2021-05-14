defmodule Camp1Web.ImageController do
  use Camp1Web, :controller
  alias Camp1.Public.Image

  def thumbnail(conn, %{"id" => id}) do
    thumb_path = Image.thumbnail_path(id)

    conn
    |> put_resp_content_type("image/jpeg")
    |> send_file(200, thumb_path)

  end

  def show(conn, %{"id" => id}) do
    path = Image.local_path(id)

    conn
    |> put_resp_content_type("image/jpeg")
    |> send_file(200, path)
  end

end
