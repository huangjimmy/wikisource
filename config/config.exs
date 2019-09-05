# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :wikisource,
  ecto_repos: [Wikisource.Repo]

# Configures the endpoint
config :wikisource, WikisourceWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "DLWilaHlFNB2BHWkgRtMut8HMLJV0caE3f1nREtJGWseEvh/RRAWp45f2eYDPXjH",
  render_errors: [view: WikisourceWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Wikisource.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
