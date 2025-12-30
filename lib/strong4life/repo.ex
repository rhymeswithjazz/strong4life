defmodule Strong4life.Repo do
  use Ecto.Repo,
    otp_app: :strong4life,
    adapter: Ecto.Adapters.Postgres
end
