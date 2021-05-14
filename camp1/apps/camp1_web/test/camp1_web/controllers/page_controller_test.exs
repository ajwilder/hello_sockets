defmodule Camp1Web.PageControllerTest do
  use Camp1Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Find your tribes"
  end
end
