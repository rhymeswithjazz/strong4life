defmodule Strong4lifeWeb.PageController do
  use Strong4lifeWeb, :controller

  def home(conn, _params) do
    # Redirect authenticated users to the dashboard
    if conn.assigns[:current_scope] do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :home)
    end
  end
end
