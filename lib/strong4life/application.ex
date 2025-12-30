defmodule Strong4life.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Strong4lifeWeb.Telemetry,
      Strong4life.Repo,
      {DNSCluster, query: Application.get_env(:strong4life, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Strong4life.PubSub},
      # Start a worker by calling: Strong4life.Worker.start_link(arg)
      # {Strong4life.Worker, arg},
      # Start to serve requests, typically the last entry
      Strong4lifeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Strong4life.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Strong4lifeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
