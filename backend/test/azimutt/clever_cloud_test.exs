defmodule Azimutt.CleverCloudTest do
  use Azimutt.DataCase
  alias Azimutt.CleverCloud
  alias Azimutt.CleverCloud.Resource
  alias Azimutt.Projects
  alias Azimutt.Utils.Result
  import Azimutt.AccountsFixtures
  import Azimutt.CleverCloudFixtures
  import Azimutt.ProjectsFixtures

  describe "resources" do
    test "get_resource/1 returns the resource with given id" do
      resource = clever_cloud_resource_fixture()
      assert {:ok, resource.id} == CleverCloud.get_resource(resource.id) |> Result.map(fn r -> r.id end)
    end

    test "create_resource/1 with valid data creates a resource" do
      valid_attrs = %{
        addon_id: "addon_xxx",
        owner_id: "orga_xxx",
        owner_name: "My Company",
        user_id: "user_yyy",
        plan: "basic",
        region: "EU",
        callback_url: "https://api.clever-cloud.com/v2/vendor/apps/addon_xxx",
        logplex_token: "logtoken_yyy"
      }

      assert {:ok, %Resource{} = resource} = CleverCloud.create_resource(valid_attrs)
      assert resource.addon_id == "addon_xxx"
      assert resource.owner_id == "orga_xxx"
      assert resource.owner_name == "My Company"
      assert resource.user_id == "user_yyy"
      assert resource.plan == "basic"
      assert resource.region == "EU"
      assert resource.callback_url == "https://api.clever-cloud.com/v2/vendor/apps/addon_xxx"
      assert resource.logplex_token == "logtoken_yyy"
      assert resource.options == nil
      assert resource.deleted_at == nil
    end

    test "create_resource/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CleverCloud.create_resource(%{})
    end

    test "update_resource_plan/2 with valid data updates the resource" do
      now = DateTime.utc_now()
      resource = clever_cloud_resource_fixture()

      update_attrs = %{
        addon_id: "addon_xxx 2",
        owner_id: "orga_xxx 2",
        owner_name: "My Company 2",
        user_id: "user_yyy 2",
        plan: "free",
        region: "EU 2",
        callback_url: "https://api.clever-cloud.com/v2/vendor/apps/addon_xxx 2",
        logplex_token: "logtoken_yyy 2",
        options: %{foo: "bar"}
      }

      assert {:ok, %Resource{} = updated} = CleverCloud.update_resource_plan(resource, update_attrs, now)
      assert updated.id == resource.id
      assert updated.addon_id == resource.addon_id
      assert updated.owner_id == resource.owner_id
      assert updated.owner_name == resource.owner_name
      assert updated.user_id == resource.user_id
      assert updated.plan == "free"
      assert updated.region == resource.region
      assert updated.callback_url == resource.callback_url
      assert updated.logplex_token == resource.logplex_token
      assert updated.options == resource.options
    end

    test "update_resource_plan/2 with invalid data returns error changeset" do
      now = DateTime.utc_now()
      resource = clever_cloud_resource_fixture()
      assert {:error, %Ecto.Changeset{}} = CleverCloud.update_resource_plan(resource, %{plan: nil}, now)
      assert {:ok, resource.id} == CleverCloud.get_resource(resource.id) |> Result.map(fn r -> r.id end)
    end

    test "delete_resource/2 deletes the resource" do
      now = DateTime.utc_now()
      user = user_fixture()
      resource = clever_cloud_resource_fixture()
      {:ok, resource} = CleverCloud.set_organization_if_needed(resource, user, now)
      project = project_fixture(resource.organization, user)

      assert {:ok, resource} = CleverCloud.get_resource(resource.id)
      assert {:ok, project} = Projects.get_project(project.id, user)

      assert {:ok, %Resource{} = _} = CleverCloud.delete_resource(resource, now)

      assert {:error, :deleted} = CleverCloud.get_resource(resource.id)
      assert {:error, :not_found} = Projects.get_project(project.id, user)
    end
  end
end
