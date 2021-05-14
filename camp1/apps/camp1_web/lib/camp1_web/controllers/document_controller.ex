defmodule Camp1Web.DocumentController do
  use Camp1Web, :controller
  alias Camp1.Public.Document


  def thumbnail(conn, %{"id" => id}) do
    thumb_path = Document.thumbnail_path(id)

    conn
    |> put_resp_content_type("image/jpeg")
    |> send_file(200, thumb_path)

  end

  def show(conn, %{"id" => id, "camp" => camp_id}) do
    id = String.to_integer id
    camp_id = String.to_integer camp_id
    content = Document.get_document_content(camp_id, id)
    path = Document.local_path(id)

    conn
    |> put_resp_content_type("application/pdf")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{content}.pdf"))
    |> send_file(200, path)

  end

end
