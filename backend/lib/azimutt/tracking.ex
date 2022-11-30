defmodule Azimutt.Tracking do
  @moduledoc "The Tracking context."
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result

  def last_project_loaded(%User{} = current_user) do
    Event
    |> where([e], e.name == :project_loaded and e.created_by_id == ^current_user.id)
    |> order_by([e], desc: e.created_at)
    |> limit(1)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def project_loaded(%User{} = current_user, %Project{} = project) do
    create_event(:project_loaded, project_data(project), %{}, current_user, project.organization.id, project.id)
  end

  def project_created(%User{} = current_user, %Project{} = project) do
    create_event(:project_created, project_data(project), %{}, current_user, project.organization.id, project.id)
  end

  def project_updated(%User{} = current_user, %Project{} = project) do
    create_event(:project_updated, project_data(project), %{}, current_user, project.organization.id, project.id)
  end

  def project_deleted(%User{} = current_user, %Project{} = project) do
    create_event(:project_deleted, project_data(project), %{}, current_user, project.organization.id, project.id)
  end

  defp project_data(%Project{} = project) do
    %{
      slug: project.slug,
      name: project.name,
      description: project.description,
      encoding_version: project.encoding_version,
      storage_kind: project.storage_kind,
      file: project.file,
      local_owner: project.local_owner_id,
      nb_sources: project.nb_sources,
      nb_tables: project.nb_tables,
      nb_columns: project.nb_columns,
      nb_relations: project.nb_relations,
      nb_types: project.nb_types,
      nb_comments: project.nb_comments,
      nb_notes: project.nb_notes,
      nb_layouts: project.nb_layouts,
      created_by: project.created_by_id,
      created_at: project.created_at,
      updated_by: project.updated_by_id,
      updated_at: project.updated_at,
      archived_by: project.archived_by_id,
      archived_at: project.archived_at
    }
  end

  defp create_event(name, data, details, %User{} = current_user, organization_id \\ nil, project_id \\ nil) do
    %Event{}
    |> Event.changeset(%{
      name: name,
      data: data,
      details: details,
      created_by: current_user,
      organization_id: organization_id,
      project_id: project_id
    })
    |> Repo.insert()
  end
end
