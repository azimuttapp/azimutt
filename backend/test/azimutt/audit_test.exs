defmodule Azimutt.AuditTest do
  use Azimutt.DataCase
  alias Azimutt.Audit

  describe "events" do
    alias Azimutt.Audit.Event
    import Azimutt.AuditFixtures
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
      assert Audit.list_events() == [event]
    end

    @tag :skip
    test "create_event/1 with valid data creates a event" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)

      assert {:ok, %Event{} = event} = Audit.project_created(user, organization.id, project.id)
      assert event.name == :project_created
    end

    @tag :skip
    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Audit.create_event(@invalid_attrs)
    end
  end
end
