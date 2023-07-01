defmodule Azimutt.CleverCloudFixtures do
  @moduledoc false
  alias Azimutt.CleverCloud

  def clever_cloud_resource_fixture(attrs \\ %{}) do
    {:ok, resource} =
      attrs
      |> Enum.into(%{
        id: Ecto.UUID.generate(),
        addon_id: "addon_xxx",
        owner_id: "orga_xxx",
        owner_name: "My Company",
        user_id: "user_yyy",
        plan: "basic",
        region: "EU",
        callback_url: "https://api.clever-cloud.com/v2/vendor/apps/addon_xxx",
        logplex_token: "logtoken_yyy",
        options: nil,
        deleted_at: nil
      })
      |> CleverCloud.create_resource()

    # fetch resource with associations loaded
    {:ok, resource} = CleverCloud.get_resource(resource.id)
    resource
  end
end
