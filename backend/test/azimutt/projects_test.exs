defmodule Azimutt.ProjectsTest do
  use Azimutt.DataCase
  import Azimutt.AccountsFixtures
  import Azimutt.OrganizationsFixtures
  alias Azimutt.Projects

  describe "projects" do
    alias Azimutt.Projects.Project
    alias Azimutt.Projects.Project.Storage
    alias Azimutt.Utils.Result
    import Azimutt.ProjectsFixtures

    test "list_projects/0 returns all projects" do
      user = user_fixture()
      user2 = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert Projects.list_projects(organization, user) |> Enum.map(fn p -> p.id end) == [project.id]
      assert Projects.list_projects(organization, user2) |> Enum.map(fn p -> p.id end) == []
    end

    test "get_project/1 returns the project with given id" do
      user = user_fixture()
      user2 = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert Projects.get_project(project.id, user) |> Result.map(fn p -> p.id end) == {:ok, project.id}
      assert Projects.get_project(project.id, user2) |> Result.map(fn p -> p.id end) == {:error, :not_found}
    end

    test "create_project/1 with valid data creates a project" do
      user = user_fixture()
      organization = organization_fixture(user)

      valid_attrs = %{
        name: "Project name",
        description: "Project description",
        storage_kind: :local,
        encoding_version: 2,
        nb_sources: 42,
        nb_tables: 42,
        nb_columns: 42,
        nb_relations: 42,
        nb_types: 42,
        nb_comments: 42,
        nb_layouts: 42,
        nb_notes: 42,
        nb_memos: 42
      }

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs, organization, user)
      assert project.organization_id == organization.id
      assert project.name == "Project name"
      assert project.slug == "project-name"
      assert project.description == "Project description"
      assert project.storage_kind == :local
      assert project.encoding_version == 2
      assert project.nb_sources == 42
      assert project.nb_tables == 42
      assert project.nb_columns == 42
      assert project.nb_relations == 42
      assert project.nb_types == 42
      assert project.nb_comments == 42
      assert project.nb_layouts == 42
      assert project.nb_notes == 42
      assert project.nb_memos == 42
    end

    @tag :skip
    test "create_project/1 with invalid data returns error changeset" do
      user = user_fixture()
      organization = organization_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(%{}, organization, user)
    end

    test "update_project/2 with valid data updates the project" do
      now = DateTime.utc_now()
      user = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)

      update_attrs = %{
        name: "Updated project name",
        description: "Updated project description",
        storage_kind: Storage.local(),
        encoding_version: 2,
        nb_sources: 1,
        nb_tables: 1,
        nb_columns: 1,
        nb_relations: 1,
        nb_types: 1,
        nb_comments: 1,
        nb_notes: 1,
        nb_layouts: 1
      }

      assert {:ok, %Project{} = project} = Projects.update_project(project, update_attrs, user, now)
      assert project.name == "Updated project name"
      assert project.description == "Updated project description"
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

    test "delete_project/1 deletes the project" do
      user = user_fixture()
      user2 = user_fixture()
      organization = organization_fixture(user)
      project = project_fixture(organization, user)
      assert {:ok, project} = Projects.get_project(project.id, user)
      assert {:error, :forbidden} = Projects.delete_project(project, user2)
      assert {:ok, %Project{}} = Projects.delete_project(project, user)
      assert {:error, :not_found} = Projects.get_project(project.id, user)
    end
  end
end
