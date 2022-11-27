defmodule Azimutt.TrackingTest do
  use Azimutt.DataCase
  alias Azimutt.Tracking

  describe "events" do
    alias Azimutt.Tracking.Event
    import Azimutt.AccountsFixtures
    import Azimutt.OrganizationsFixtures
    import Azimutt.ProjectsFixtures

    @tag :skip
    test "create_event/1 with valid data creates a event" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)

      assert {:ok, %Event{} = event} = Tracking.project_created(user, project)
      assert event.name == :project_created
    end
  end
end
