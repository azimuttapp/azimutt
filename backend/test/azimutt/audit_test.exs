defmodule Azimutt.TrackingTest do
  use Azimutt.DataCase
  alias Azimutt.Tracking

  describe "events" do
    alias Azimutt.Tracking.Event
    import Azimutt.TrackingFixtures
    import Azimutt.AccountsFixtures
    import Azimutt.OrganizationsFixtures
    import Azimutt.ProjectsFixtures

    @invalid_attrs %{created_at: nil, details: nil, name: nil}

    @tag :skip
    test "list_events/0 returns all events" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      event = project_created_fixture(user, organization, project)
      assert Tracking.list_events() == [event]
    end

    @tag :skip
    test "create_event/1 with valid data creates a event" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)

      assert {:ok, %Event{} = event} = Tracking.project_created(user, organization.id, project.id)
      assert event.name == :project_created
    end

    @tag :skip
    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracking.create_event(@invalid_attrs)
    end
  end
end
