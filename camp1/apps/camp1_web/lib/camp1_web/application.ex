defmodule Camp1Web.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      Camp1Web.Telemetry,
      # Start the Endpoint (http/https)
      Camp1Web.Endpoint
      # Start a worker by calling: Camp1Web.Worker.start_link(arg)
      # {Camp1Web.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Camp1Web.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Camp1Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
