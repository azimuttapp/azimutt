defmodule Azimutt.TrackingTest do
  use Azimutt.DataCase
  alias Azimutt.Tracking
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result

  describe "events" do
    import Azimutt.AccountsFixtures
    import Azimutt.OrganizationsFixtures
    import Azimutt.ProjectsFixtures

    test "last_used_project/1 fetch last project_loaded for a user" do
      user = user_fixture()
      user2 = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      project2 = project_fixture(organization, user)

      assert {:ok, %Event{} = _event} = Tracking.project_loaded(user, project)
      assert {:ok, %Event{} = event2} = Tracking.project_loaded(user, project2)
      assert {:ok, event2.id} == Tracking.last_used_project(user) |> Result.map(fn e -> e.id end)
      assert {:error, :not_found} == Tracking.last_used_project(user2)
    end

    test "create one event of each kind" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)

      assert {:ok, %Event{} = project_created} = Tracking.project_created(user, project)
      assert project_created.name == "project_created"

      assert {:ok, %Event{} = project_loaded} = Tracking.project_loaded(user, project)
      assert project_loaded.name == "project_loaded"

      assert {:ok, %Event{} = project_updated} = Tracking.project_updated(user, project)
      assert project_updated.name == "project_updated"

      assert {:ok, %Event{} = project_deleted} = Tracking.project_deleted(user, project)
      assert project_deleted.name == "project_deleted"
    end
  end
end
