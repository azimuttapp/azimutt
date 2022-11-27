defmodule Azimutt.ProjectsTest do
  use Azimutt.DataCase
  import Azimutt.AccountsFixtures
  import Azimutt.OrganizationsFixtures
  alias Azimutt.Projects

  describe "projects" do
    alias Azimutt.Projects.Project
    import Azimutt.ProjectsFixtures

    @tag :skip
    test "list_projects/0 returns all projects" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert Projects.list_projects(organization, user) == [project]
    end

    @tag :skip
    test "get_project/1 returns the project with given id" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert Projects.get_project(project.id, user) == {:ok, project}
    end

    @tag :skip
    test "create_project/1 with valid data creates a project" do
      user = user_fixture()
      organization = organization_fixture(user)

      valid_attrs = %{
        storage_kind: :local,
        name: "Project name",
        description: "Project description",
        encoding_version: 2,
        nb_sources: 42,
        nb_tables: 42,
        nb_columns: 42,
        nb_relations: 42,
        nb_types: 42,
        nb_comments: 42,
        nb_notes: 42,
        nb_layouts: 42
      }

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs, organization, user)
      assert project.organization_id == organization.id
      assert project.storage_kind == :local
      assert project.name == "Project name"
      assert project.slug == "project-name"
      assert project.description == "Project description"
      assert project.encoding_version == 2
      assert project.nb_sources == 42
      assert project.nb_tables == 42
      assert project.nb_columns == 42
      assert project.nb_relations == 42
      assert project.nb_types == 42
      assert project.nb_comments == 42
      assert project.nb_notes == 42
      assert project.nb_layouts == 42
    end

    @tag :skip
    test "create_project/1 with invalid data returns error changeset" do
      user = user_fixture()
      organization = organization_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(%{}, organization, user)
    end

    @tag :skip
    test "update_project/2 with valid data updates the project" do
      now = DateTime.utc_now()
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)

      update_attrs = %{
        description: "some updated description",
        is_archived: false,
        is_favorited: false,
        last_modifier: 43,
        name: "some updated name",
        nb_columns: 43,
        nb_layouts: 43,
        nb_relations: 43,
        nb_sources: 43,
        nb_tables: 43,
        organization_id: 43,
        storage_kink: "some updated storage_kink",
        storage_link: "some updated storage_link",
        storage_version: "some updated storage_version"
      }

      assert {:ok, %Project{} = project} = Projects.update_project(project, update_attrs, user, now)
      assert project.description == "some updated description"
      assert project.is_archived == false
      assert project.is_favorited == false
      assert project.last_modifier == 43
      assert project.name == "some updated name"
      assert project.nb_columns == 43
      assert project.nb_layouts == 43
      assert project.nb_relations == 43
      assert project.nb_sources == 43
      assert project.nb_tables == 43
      assert project.organization_id == 43
      assert project.slug == "some-updated-name"
      assert project.storage_kink == "some updated storage_kink"
      assert project.storage_link == "some updated storage_link"
      assert project.storage_version == "some updated storage_version"
    end

    @tag :skip
    test "update_project/2 with invalid data returns error changeset" do
      now = DateTime.utc_now()
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, %{name: nil}, user, now)
      assert {:ok, project} == Projects.get_project(project.id, user)
    end

    @tag :skip
    test "delete_project/1 deletes the project" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert {:ok, %Project{}} = Projects.delete_project(project, user)
      assert {:error, :not_found} = Projects.get_project(project.id, user)
    end
  end
end
