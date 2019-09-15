use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :wikisource, WikisourceWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :elastix,
  url: System.get_env("WIKISOURCE_ELASTIC_URL", "http://elasticsearc:9200")

# Configure your database
config :wikisource, Wikisource.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "wikisource",
  password: "123456",
  database: "wikisource_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
