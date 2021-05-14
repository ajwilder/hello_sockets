defmodule RumblTest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      RumblTest.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: RumblTest.PubSub}
      # Start a worker by calling: RumblTest.Worker.start_link(arg)
      # {RumblTest.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: RumblTest.Supervisor)
  end
end
