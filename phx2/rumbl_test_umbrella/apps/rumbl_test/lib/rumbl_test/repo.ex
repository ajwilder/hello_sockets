defmodule RumblTest.Repo do
  use Ecto.Repo,
    otp_app: :rumbl_test,
    adapter: Ecto.Adapters.Postgres
end
