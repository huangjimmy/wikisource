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
           adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "87dskjl239agfzawl20ksz00"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :phoenix,
  template_engines: [leex: Phoenix.LiveView.Engine]

config :wikisource,
  table: Wikisource.SessionStore,
  max_age: 7200,
  check_interval: 180

config :libcluster,
  topologies: [
    wikisource: [
      # The selected clustering strategy. Required.
      strategy: Cluster.Strategy.Gossip,
      connect: {Wikisource.SessionStore, :connect_node, []},
      # The function to use for disconnecting nodes. The node
      # name will be appended to the argument list. Optional
      disconnect: {:erlang, :disconnect_node, []},
      # The function to use for listing nodes.
      # This function must return a list of node names. Optional
      list_nodes: {Wikisource.SessionStore, :nodes, []},
      config: [
        secret: "wikisource_node",
      ]
    ]
  ]

config :mnesiac,
  stores: [Wikisource.SessionStore],
  schema_type: :disc_copies, # defaults to :ram_copies
  table_load_timeout: 600_000 # milliseconds, default is 600_000
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
