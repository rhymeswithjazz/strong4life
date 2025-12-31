defmodule Strong4lifeWeb.AdminController do
  use Strong4lifeWeb, :controller

  def reset_database(conn, %{"confirm" => "yes-delete-everything"}) do
    # Delete all users (which cascades to sessions, sets, etc.)
    {count, _} = Strong4life.Repo.delete_all(Strong4life.Accounts.User)

    json(conn, %{
      success: true,
      message: "Database cleared successfully",
      users_deleted: count
    })
  end

  def reset_database(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Missing confirmation parameter",
      hint: "Add ?confirm=yes-delete-everything to the URL"
    })
  end
end
