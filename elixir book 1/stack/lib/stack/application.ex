defmodule Stack.Application do
  use Application

  def start(_type, _args) do
    children = [
      { Stack.Stash, ['butts'] },
      { Stack.Server, nil }
    ]

    opts = [strategy: :one_for_one, name: Stack.Supervisor]
    Supervisor.start_link(children,opts)
  end
end
