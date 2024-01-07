defmodule Azimutt.Projects do
  @moduledoc "The Projects context."
  import Ecto.Query, warn: false
  require Logger
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Projects.Project
  alias Azimutt.Projects.Project.Storage
  alias Azimutt.Projects.ProjectFile
  alias Azimutt.Projects.ProjectToken
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
      [p, _, om],
      p.id == ^id and om.user_id == ^current_user.id and
        (p.storage_kind == :remote or (p.storage_kind == :local and p.local_owner_id == ^current_user.id))
    )
    |> Repo.one()
    |> Result.from_nillable()
    |> Result.flat_map_error(fn err -> get_project(id, nil) |> Result.map_error(fn _ -> err end) end)
  end

  def get_project(id, current_user) when is_nil(current_user) do
    project_query_no_join()
    |> where([p], p.id == ^id and p.storage_kind == :remote and p.visibility != :none)
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

  def update_project_file(%Project{} = project, content, %User{} = current_user, now) do
    can_update =
      project_query()
      |> where([p, _, om], p.id == ^project.id and p.storage_kind == :remote and (om.user_id == ^current_user.id or p.visibility != :write))
      |> Repo.exists?()

    if can_update do
      project
      |> Project.update_project_file_changeset(content, current_user, now)
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
      ProjectToken
      |> where([pt], pt.project_id == ^project.id)
      |> Repo.delete_all()

      Repo.delete(project)
      |> Result.tap(fn p -> Tracking.project_deleted(current_user, p) end)
    else
      {:error, :forbidden}
    end
  end

  def get_project_content(%Project{} = project) do
    if project.storage_kind == Storage.remote() do
      # FIXME: handle spaces in name
      file_url = ProjectFile.url({project.file, project}, signed: true)

      if Application.get_env(:waffle, :storage) == Waffle.Storage.Local do
        File.read("./#{file_url}")
      else
        HTTPoison.get(file_url) |> Result.map(fn resp -> resp.body end)
      end
    else
      {:error, :not_remote}
    end
  end

  def update_project_content(project_id, current_user, now, f) do
    with {:ok, %Project{} = project} <- get_project(project_id, current_user),
         {:ok, content} <- get_project_content(project),
         {:ok, json} <- Jason.decode(content),
         json_updated = f.(json),
         {:ok, content_updated} <- Jason.encode(json_updated),
         {:ok, %Project{} = _project_updated} <- update_project_file(project, content_updated, current_user, now),
         do: {:ok, json_updated}
  end

  def list_project_tokens(project_id, %User{} = current_user, now) do
    project_query()
    |> where([p, _, om], p.id == ^project_id and p.storage_kind == :remote and om.user_id == ^current_user.id)
    |> Repo.one()
    |> Result.from_nillable()
    |> Result.map(fn project ->
      ProjectToken
      |> where([pt], pt.project_id == ^project.id and is_nil(pt.revoked_at) and (is_nil(pt.expire_at) or pt.expire_at > ^now))
      |> preload(:created_by)
      |> Repo.all()
    end)
  end

  def create_project_token(project_id, %User{} = current_user, attrs) do
    project_query()
    |> where([p, _, om], p.id == ^project_id and p.storage_kind == :remote and om.user_id == ^current_user.id)
    |> Repo.one()
    |> Result.from_nillable()
    |> Result.flat_map(fn project ->
      %ProjectToken{}
      |> ProjectToken.create_changeset(%{
        name: attrs["name"],
        expire_at: attrs["expire_at"],
        project_id: project.id,
        created_by: current_user
      })
      |> Repo.insert()
    end)
  end

  def revoke_project_token(token_id, %User{} = current_user, now) do
    ProjectToken
    |> join(:inner, [pt], p in Project, on: pt.project_id == p.id)
    |> join(:inner, [_, p], o in Organization, on: p.organization_id == o.id)
    |> join(:inner, [_, _, o], om in OrganizationMember, on: om.organization_id == o.id)
    |> preload(:revoked_by)
    |> where(
      [pt, p, _, om],
      pt.id == ^token_id and is_nil(pt.revoked_at) and (is_nil(pt.expire_at) or pt.expire_at > ^now) and
        p.storage_kind == :remote and om.user_id == ^current_user.id
    )
    |> Repo.one()
    |> Result.from_nillable()
    |> Result.flat_map(fn token ->
      token
      |> ProjectToken.revoke_changeset(current_user, now)
      |> Repo.update()
    end)
  end

  def access_project(project_id, token_id, maybe_current_user, now) do
    ProjectToken
    |> where(
      [pt],
      pt.project_id == ^project_id and pt.id == ^token_id and is_nil(pt.revoked_at) and (is_nil(pt.expire_at) or pt.expire_at > ^now)
    )
    |> Repo.one()
    |> Result.from_nillable()
    |> Result.flat_map(fn token ->
      project_query_no_join()
      |> where([p, _, _], p.id == ^project_id and p.storage_kind == :remote)
      |> Repo.one()
      |> Result.from_nillable()
      |> Result.filter(fn p -> Organizations.get_organization_plan(p.organization, maybe_current_user) |> Result.exists(& &1.private_links) end, :not_found)
      |> Result.tap(fn _ -> token |> ProjectToken.access_changeset(now) |> Repo.update() end)
    end)
  end

  def load_project(project_id, maybe_current_user, token_id, now) do
    if token_id do
      access_project(project_id, token_id, maybe_current_user, now)
    else
      get_project(project_id, maybe_current_user)
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
    |> order_by([p, _, _], desc: p.updated_at)
    |> preload(:organization)
    |> preload(organization: [:clever_cloud_resource, :heroku_resource])
    |> preload(:updated_by)
  end

  defp project_query_no_join do
    Project
    |> order_by([p], desc: p.updated_at)
    |> preload(:organization)
    |> preload(organization: [:clever_cloud_resource, :heroku_resource])
    |> preload(:updated_by)
  end
end
