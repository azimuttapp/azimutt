defmodule Azimutt.Projects do
  @moduledoc "The Projects context."
  import Ecto.Query, warn: false
  require Logger
  alias Azimutt.Accounts.User
  alias Azimutt.Audit
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Projects.Project
  alias Azimutt.Projects.Project.Storage
  alias Azimutt.Repo
  alias Azimutt.Utils.Result

  def list_projects(%Organization{} = organization, %User{} = current_user) do
    Project
    |> join(:inner, [p], o in Organization, on: p.organization_id == o.id)
    |> join(:inner, [_, o], om in OrganizationMember, on: om.organization_id == o.id)
    |> where(
      [p, o, om],
      om.user_id == ^current_user.id and
        o.id == ^organization.id and
        (p.storage_kind == :remote or (p.storage_kind == :local and p.local_owner_id == ^current_user.id))
    )
    |> preload(:organization)
    |> preload(:updated_by)
    |> Repo.all()
  end

  def get_project(id, %User{} = current_user) do
    Project
    |> join(:inner, [p], o in Organization, on: p.organization_id == o.id)
    |> join(:inner, [_, o], om in OrganizationMember, on: om.organization_id == o.id)
    |> where(
      [p, _, om],
      om.user_id == ^current_user.id and
        p.id == ^id and
        (p.storage_kind == :remote or (p.storage_kind == :local and p.local_owner_id == ^current_user.id))
    )
    |> preload(:organization)
    |> preload(:updated_by)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def create_project(attrs, %Organization{} = organization, %User{} = current_user) do
    if organization |> Organizations.has_member?(current_user) do
      # FIXME: atom for seeds and string for api, how make it work for both?
      try do
        storage = Storage.from_string_or_atom(attrs[:storage_kind] || attrs["storage_kind"])
        uuid = Ecto.UUID.generate()

        cond do
          storage == Storage.local() -> attrs |> Project.create_local_changeset(organization, current_user, uuid)
          storage == Storage.remote() -> attrs |> Project.create_remote_changeset(organization, current_user, uuid)
          true -> raise "Invalid storage: '#{storage}'"
        end
        |> Repo.insert()
        |> Result.tap(fn p -> Audit.project_created(current_user, p.organization.id, p.id) end)
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
    # FIXME: atom for seeds and string for api, how make it work for both?
    storage = Storage.from_string_or_atom(attrs[:storage_kind] || attrs["storage_kind"])

    cond do
      storage == Storage.local() -> project |> Project.update_local_changeset(attrs, current_user, now)
      storage == Storage.remote() -> project |> Project.update_remote_changeset(attrs, current_user, now)
      true -> raise "Invalid storage: '#{storage}'"
    end
    |> Repo.update()
    |> Result.tap(fn p -> Audit.project_updated(current_user, p.organization.id, p.id) end)
  end

  def delete_project(%Project{} = project, %User{} = current_user) do
    Repo.delete(project)
    |> Result.tap(fn p -> Audit.project_deleted(current_user, p.organization.id, p.id) end)
  end
end
