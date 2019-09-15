defmodule WikisourceWeb.PageControllerTest do
  use WikisourceWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "b_searchboxForm"
  end

  test "GET /app", %{conn: conn} do
    conn = get conn, "/app"
    assert html_response(conn, 200) =~ "b_searchboxForm"
  end
end
