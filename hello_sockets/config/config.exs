# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :hello_sockets, HelloSocketsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "XQFtlUL52NfLmO3kTOOnBa4U0Z2Tjm5RJ3eBEG+2BrD/CpPiFGNilVdWEdq2Zcxy",
  render_errors: [view: HelloSocketsWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: HelloSockets.PubSub,
  live_view: [signing_salt: "wtdpe3xb"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
