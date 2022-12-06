defmodule Azimutt.HerokuFixtures do
  @moduledoc false

  def resource_fixture(attrs \\ %{}) do
    {:ok, resource} =
      attrs
      |> Enum.into(%{
        heroku_id: Ecto.UUID.generate(),
        name: "acme-inc-primary-database",
        plan: "basic",
        region: "amazon-web-services::us-east-1",
        options: nil,
        callback: "https://api.heroku.com/addons/#{Ecto.UUID.generate()}",
        oauth_code: Ecto.UUID.generate(),
        oauth_type: "authorization_code",
        oauth_expire: Timex.shift(DateTime.utc_now(), days: 7),
        deleted_at: nil
      })
      |> Azimutt.Heroku.create_resource()

    resource
  end
end
