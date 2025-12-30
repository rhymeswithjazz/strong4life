defmodule Strong4lifeWeb.HealthController do
  use Strong4lifeWeb, :controller

  @doc """
  Health check endpoint for Docker and load balancers.
  Returns 200 OK with status JSON if the app is running.
  """
  def index(conn, _params) do
    # Basic health check - just confirms the app is running
    # Can be extended to check database connectivity, etc.
    json(conn, %{status: "ok", timestamp: DateTime.utc_now()})
  end
end

