defmodule Azimutt.ProjectsFixtures do
  @moduledoc false
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization

  def project_fixture(%Organization{} = organization, %User{} = user, attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
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
        organization_id: 1,
        slug: "some slug",
        storage_kink: "some storage_kink",
        storage_link: "some storage_link",
        storage_version: "some storage_version"
      })
      |> Azimutt.Projects.create_project(organization, user)

    project
  end
end
