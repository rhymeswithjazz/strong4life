defmodule Strong4lifeWeb.PageControllerTest do
  use Strong4lifeWeb.ConnCase

  test "GET / shows landing page for unauthenticated users", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Stronk"
    assert html_response(conn, 200) =~ "Get Started Free"
  end
end
