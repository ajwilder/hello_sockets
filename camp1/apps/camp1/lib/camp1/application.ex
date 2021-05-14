defmodule Camp1.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Camp1.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Camp1.PubSub}
      # Start a worker by calling: Camp1.Worker.start_link(arg)
      # {Camp1.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Camp1.Supervisor)
  end
end
