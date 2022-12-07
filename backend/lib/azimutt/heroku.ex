defmodule Azimutt.Heroku do
  @moduledoc "Context for the Heroku addon"
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Heroku.Resource
  alias Azimutt.Heroku.ResourceMember
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Utils.Result

  def get_resource(heroku_id) do
    Repo.get_by(Resource, heroku_id: heroku_id)
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
    resource
    |> Resource.delete_changeset(now)
    |> Repo.update()
  end
end
