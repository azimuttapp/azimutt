defmodule Azimutt.Heroku do
  @moduledoc "Context for the Heroku addon"
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Heroku.Resource
  alias Azimutt.Heroku.ResourceMember
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Utils.Result

  def all_resources do
    Resource |> preload(:project) |> Repo.all()
  end

  def get_resource(id) do
    Resource
    |> preload(:project)
    |> Repo.get(id)
    |> Result.from_nillable()
    |> Result.filter_not(fn r -> r.deleted_at end, :deleted)
  end

  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_resource_plan(%Resource{} = resource, attrs, now) do
    resource
    |> Resource.update_plan_changeset(attrs, now)
    |> Repo.update()
  end

  def set_resource_project(%Resource{} = resource, %Project{} = project, now) do
    cond do
      resource.project == nil ->
        resource
        |> Resource.set_project_changeset(project, now)
        |> Repo.update()

      resource.project.id == project.id ->
        {:ok, resource}

      true ->
        {:error, :project_already_set}
    end
  end

  def get_resource_member(%Resource{} = resource, %User{} = user) do
    ResourceMember
    |> where([rm], rm.heroku_resource_id == ^resource.id and rm.user_id == ^user.id)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def create_resource_member(%Resource{} = resource, %User{} = user) do
    ResourceMember.new_member_changeset(resource, user)
    |> Repo.insert()
  end

  def set_resource_member(%Resource{} = resource, %User{} = user) do
    get_resource_member(resource, user)
    |> Result.flat_map_error(fn _ -> create_resource_member(resource, user) end)
  end

  def delete_resource(%Resource{} = resource, now) do
    res =
      resource
      |> Resource.delete_changeset(now)
      |> Repo.update()

    if resource.project do
      Repo.delete(resource.project)
    end

    res
  end
end
