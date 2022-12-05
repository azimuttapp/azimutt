defmodule Azimutt.HerokuFixtures do
  @moduledoc false

  def resource_fixture(attrs \\ %{}) do
    {:ok, resource} =
      attrs
      |> Enum.into(%{
        heroku_id: "85c71086-5e50-4057-b269-34b628aff1b1",
        name: "acme-inc-primary-database",
        plan: "basic",
        region: "amazon-web-services::us-east-1",
        options: nil,
        callback: "https://api.heroku.com/addons/5f80ab31-8b20-4a93-9950-732bc1f97ca9",
        oauth_code: "635248df-7717-4446-bf4e-258ae33b8c18",
        oauth_type: "authorization_code",
        oauth_expire: Timex.shift(DateTime.utc_now(), days: 7),
        deleted_at: nil
      })
      |> Azimutt.Heroku.create_resource()

    resource
  end
end
