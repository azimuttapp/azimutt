defmodule Azimutt.HerokuTest do
  use Azimutt.DataCase
  alias Azimutt.Heroku

  describe "resources" do
    alias Azimutt.Heroku.Resource
    import Azimutt.HerokuFixtures

    test "get_resource/1 returns the resource with given id" do
      resource = resource_fixture()
      assert Heroku.get_resource(resource.heroku_id) == {:ok, resource}
    end

    test "create_resource/1 with valid data creates a resource" do
      now = DateTime.utc_now()

      valid_attrs = %{
        heroku_id: "01234567-89ab-cdef-0123-456789abcdef",
        name: "acme-inc-primary-database",
        plan: "basic",
        region: "amazon-web-services::us-east-1",
        options: nil,
        callback: "https://api.heroku.com/addons/01234567-89ab-cdef-0123-456789abcdef",
        oauth_code: "7488a646-e31f-11e4-aace-600308960662",
        oauth_type: "authorization_code",
        oauth_expire: Timex.shift(now, days: 7),
        deleted_at: nil
      }

      assert {:ok, %Resource{} = resource} = Heroku.create_resource(valid_attrs)
      assert resource.heroku_id == "01234567-89ab-cdef-0123-456789abcdef"
      assert resource.name == "acme-inc-primary-database"
      assert resource.plan == "basic"
      assert resource.region == "amazon-web-services::us-east-1"
      assert resource.options == nil
      assert resource.callback == "https://api.heroku.com/addons/01234567-89ab-cdef-0123-456789abcdef"
      assert resource.oauth_code == "7488a646-e31f-11e4-aace-600308960662"
      assert resource.oauth_type == "authorization_code"
      assert resource.oauth_expire == Timex.shift(now, days: 7)
      assert resource.deleted_at == nil
    end

    test "create_resource/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Heroku.create_resource(%{heroku_id: nil})
    end

    test "update_resource_plan/2 with valid data updates the resource" do
      now = DateTime.utc_now()
      resource = resource_fixture()

      update_attrs = %{
        heroku_id: "7488a646-e31f-11e4-aace-600308960668",
        name: "some updated name",
        plan: "some updated plan",
        region: "some updated region",
        options: %{foo: "bar"},
        callback: "some updated callback",
        oauth_code: "7488a646-e31f-11e4-aace-600308960668",
        oauth_type: "some updated oauth_type",
        oauth_expire: ~U[2022-12-05 11:00:00.000000Z]
      }

      assert {:ok, %Resource{} = updated} = Heroku.update_resource_plan(resource, update_attrs, now)
      assert updated.heroku_id == resource.heroku_id
      assert updated.name == resource.name
      assert updated.plan == "some updated plan"
      assert updated.region == resource.region
      assert updated.options == resource.options
      assert updated.callback == resource.callback
      assert updated.oauth_code == resource.oauth_code
      assert updated.oauth_type == resource.oauth_type
      assert updated.oauth_expire == resource.oauth_expire
    end

    test "update_resource_plan/2 with invalid data returns error changeset" do
      now = DateTime.utc_now()
      resource = resource_fixture()
      assert {:error, %Ecto.Changeset{}} = Heroku.update_resource_plan(resource, %{plan: nil}, now)
      assert {:ok, resource} == Heroku.get_resource(resource.heroku_id)
    end

    test "delete_resource/2 deletes the resource" do
      now = DateTime.utc_now()
      resource = resource_fixture()
      assert resource.deleted_at == nil
      assert {:ok, %Resource{} = _} = Heroku.delete_resource(resource, now)
      assert {:error, :deleted} = Heroku.get_resource(resource.heroku_id)
    end
  end
end
