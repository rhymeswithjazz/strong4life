defmodule Strong4lifeWeb.ErrorJSONTest do
  use Strong4lifeWeb.ConnCase, async: true

  test "renders 404" do
    assert Strong4lifeWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Strong4lifeWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
