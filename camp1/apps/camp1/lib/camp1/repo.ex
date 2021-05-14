defmodule Camp1.Repo do
  use Ecto.Repo,
    otp_app: :camp1,
    adapter: Ecto.Adapters.Postgres

  def count(table) do
    aggregate(table, :count, :id)
  end
end
