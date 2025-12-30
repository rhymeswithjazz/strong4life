defmodule Strong4lifeWeb.UserSessionHTML do
  use Strong4lifeWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:strong4life, Strong4life.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
