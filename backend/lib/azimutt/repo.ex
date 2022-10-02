defmodule Azimutt.Repo do
  use Ecto.Repo,
    otp_app: :azimutt,
    adapter: Ecto.Adapters.Postgres
end
