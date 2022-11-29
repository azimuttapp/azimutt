defmodule Azimutt.ProjectsFixtures do
  @moduledoc false
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project.Storage

  def project_fixture(%Organization{} = organization, %User{} = user, attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        name: "Project name",
        description: "Project description",
        storage_kind: Storage.local(),
        encoding_version: 2,
        nb_sources: 42,
        nb_tables: 42,
        nb_columns: 42,
        nb_relations: 42,
        nb_types: 42,
        nb_comments: 42,
        nb_notes: 42,
        nb_layouts: 42
      })
      |> Azimutt.Projects.create_project(organization, user)

    project
  end
end
