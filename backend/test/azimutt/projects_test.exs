defmodule Azimutt.ProjectsTest do
  use Azimutt.DataCase
  import Azimutt.AccountsFixtures
  import Azimutt.OrganizationsFixtures
  alias Azimutt.Projects

  describe "projects" do
    alias Azimutt.Projects.Project

    import Azimutt.ProjectsFixtures

    @invalid_attrs %{
      description: nil,
      is_archived: nil,
      is_favorited: nil,
      last_modifier: nil,
      name: nil,
      nb_columns: nil,
      nb_layouts: nil,
      nb_relations: nil,
      nb_sources: nil,
      nb_tables: nil,
      organization_id: nil,
      slug: nil,
      storage_kink: nil,
      storage_link: nil,
      storage_version: nil
    }

    @tag :skip
    test "list_projects/0 returns all projects" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert Projects.list_projects() == [project]
    end

    @tag :skip
    test "get_project/1 returns the project with given id" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert Projects.get_project(project.id) == {:ok, project}
    end

    @tag :skip
    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{
        description: "some description",
        is_archived: true,
        is_favorited: true,
        last_modifier: 42,
        name: "some name",
        nb_columns: 42,
        nb_layouts: 42,
        nb_relations: 42,
        nb_sources: 42,
        nb_tables: 42,
        organization_id: 42,
        storage_kink: "some storage_kink",
        storage_link: "some storage_link",
        storage_version: "some storage_version"
      }

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs)
      assert project.description == "some description"
      assert project.is_archived == true
      assert project.is_favorited == true
      assert project.last_modifier == 42
      assert project.name == "some name"
      assert project.nb_columns == 42
      assert project.nb_layouts == 42
      assert project.nb_relations == 42
      assert project.nb_sources == 42
      assert project.nb_tables == 42
      assert project.organization_id == 42
      assert project.slug == "some-name"
      assert project.storage_kink == "some storage_kink"
      assert project.storage_link == "some storage_link"
      assert project.storage_version == "some storage_version"
    end

    @tag :skip
    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
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
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs, user, now)
      assert {:ok, project} == Projects.get_project(project.id)
    end

    @tag :skip
    test "delete_project/1 deletes the project" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert {:error, :not_found} = Projects.get_project(project.id)
    end

    @tag :skip
    test "change_project/1 returns a project changeset" do
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end
end
