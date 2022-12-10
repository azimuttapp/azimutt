defmodule Azimutt.Projects do
  @moduledoc "The Projects context."
  import Ecto.Query, warn: false
  require Logger
  alias Azimutt.Accounts.User
  alias Azimutt.Heroku.Resource
  alias Azimutt.Heroku.ResourceMember
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Projects.Project
  alias Azimutt.Projects.Project.Storage
  alias Azimutt.Repo
  alias Azimutt.Tracking
  alias Azimutt.Utils.Result

  def list_projects(%Organization{} = organization, %User{} = current_user) do
    project_query()
    |> where(
      [p, o, om],
      om.user_id == ^current_user.id and
        o.id == ^organization.id and
        (p.storage_kind == :remote or (p.storage_kind == :local and p.local_owner_id == ^current_user.id))
    )
    |> Repo.all()
  end

  def get_project(id, %User{} = current_user) do
    project_query()
    |> where(
      [p, _, om, _, hm],
      p.id == ^id and
        (p.storage_kind == :remote or (p.storage_kind == :local and p.local_owner_id == ^current_user.id)) and
        (om.user_id == ^current_user.id or hm.user_id == ^current_user.id or p.visibility != :none)
    )
    |> Repo.one()
    |> Result.from_nillable()
  end

  def get_project(id, current_user) when is_nil(current_user) do
    project_query()
    |> where([p, _, om], p.id == ^id and p.storage_kind == :remote and p.visibility != :none)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def create_project(attrs, %Organization{} = organization, %User{} = current_user) do
    if organization |> Organizations.has_member?(current_user) do
      try do
        storage = get_storage(attrs)
        uuid = Ecto.UUID.generate()

        cond do
          storage == Storage.local() -> attrs |> Project.create_local_changeset(organization, current_user, uuid)
          storage == Storage.remote() -> attrs |> Project.create_remote_changeset(organization, current_user, uuid)
          true -> raise "Invalid storage: '#{storage}'"
        end
        |> Repo.insert()
        |> Result.tap(fn p -> Tracking.project_created(current_user, p) end)
      rescue
        e ->
          Logger.error(Exception.format(:error, e, __STACKTRACE__))
          {:error, "can't insert project"}
      end
    else
      {:error, :unauthorized}
    end
  end

  def update_project(%Project{} = project, attrs, %User{} = current_user, now) do
    storage = get_storage(attrs)

    can_update =
      project_query()
      |> where(
        [p, _, om],
        p.id == ^project.id and
          (p.storage_kind == :remote or (p.storage_kind == :local and p.local_owner_id == ^current_user.id)) and
          (om.user_id == ^current_user.id or p.visibility != :write)
      )
      |> Repo.exists?()

    if can_update do
      cond do
        storage == Storage.local() -> project |> Project.update_local_changeset(attrs, current_user, now)
        storage == Storage.remote() -> project |> Project.update_remote_changeset(attrs, current_user, now)
        true -> raise "Invalid storage: '#{storage}'"
      end
      |> Repo.update()
      |> Result.tap(fn p -> Tracking.project_updated(current_user, p) end)
    else
      {:error, :forbidden}
    end
  end

  def delete_project(%Project{} = project, %User{} = current_user) do
    can_delete =
      project_query()
      |> where(
        [p, _, om],
        p.id == ^project.id and
          (p.storage_kind == :remote or (p.storage_kind == :local and p.local_owner_id == ^current_user.id)) and
          om.user_id == ^current_user.id
      )
      |> Repo.exists?()

    if can_delete do
      Repo.delete(project)
      |> Result.tap(fn p -> Tracking.project_deleted(current_user, p) end)
    else
      {:error, :forbidden}
    end
  end

  defp get_storage(attrs) do
    # FIXME: atom for seeds and string for api, how make it work for both?
    Storage.from_string_or_atom(attrs[:storage_kind] || attrs["storage_kind"])
  end

  defp project_query do
    # TODO: how to also mutualise the where clause?
    Project
    |> join(:inner, [p], o in Organization, on: p.organization_id == o.id)
    |> join(:inner, [_, o], om in OrganizationMember, on: om.organization_id == o.id)
    |> join(:left, [p, _, _], h in Resource, on: h.project_id == p.id)
    |> join(:left, [p, _, _, h], hm in ResourceMember, on: hm.heroku_resource_id == h.id)
    |> preload(:organization)
    |> preload(:heroku_resource)
    |> preload(:updated_by)
  end
end
