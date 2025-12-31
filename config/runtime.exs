import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/strong4life start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :strong4life, Strong4lifeWeb.Endpoint, server: true
end

config :strong4life, Strong4lifeWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :strong4life, Strong4life.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :strong4life, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :strong4life, Strong4lifeWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :strong4life, Strong4lifeWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :strong4life, Strong4lifeWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # Configure SMTP mailer for production
  smtp_host = System.get_env("SMTP_HOST")
  smtp_port = String.to_integer(System.get_env("SMTP_PORT") || "587")
  smtp_username = System.get_env("SMTP_USERNAME")
  smtp_password = System.get_env("SMTP_PASSWORD")
  smtp_from_email = System.get_env("SMTP_FROM_EMAIL") || "noreply@#{host}"

  if smtp_host && smtp_username && smtp_password do
    # Port 465 uses SSL, port 587 uses STARTTLS
    {ssl_config, tls_config} =
      if smtp_port == 465 do
        {true, :never}
      else
        {false, :always}
      end

    IO.puts("SMTP Configuration:")
    IO.puts("  Host: #{smtp_host}")
    IO.puts("  Port: #{smtp_port}")
    IO.puts("  Username: #{smtp_username}")
    IO.puts("  SSL: #{ssl_config}, TLS: #{tls_config}")

    config :strong4life, Strong4life.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: smtp_host,
      port: smtp_port,
      username: smtp_username,
      password: smtp_password,
      ssl: ssl_config,
      tls: tls_config,
      tls_options: [
        verify: :verify_peer,
        versions: [:"tlsv1.2", :"tlsv1.3"],
        cacerts: :public_key.cacerts_get()
      ],
      auth: :always,
      retries: 2

    config :strong4life, :smtp_from_email, smtp_from_email
  else
    IO.puts("SMTP Configuration SKIPPED - missing environment variables:")
    IO.puts("  SMTP_HOST: #{if smtp_host, do: "SET", else: "MISSING"}")
    IO.puts("  SMTP_USERNAME: #{if smtp_username, do: "SET", else: "MISSING"}")
    IO.puts("  SMTP_PASSWORD: #{if smtp_password, do: "SET", else: "MISSING"}")
  end
end
