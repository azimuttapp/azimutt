defmodule Azimutt.Heroku do
  @moduledoc "Context for the Heroku addon"
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Heroku.Resource
  alias Azimutt.Organizations
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Repo
  alias Azimutt.Utils.Result

  def all_resources do
    Resource
    |> preload(:organization)
    |> preload(organization: :projects)
    |> Repo.all()
  end

  def get_resource(id) do
    Resource
    |> preload(:organization)
    |> preload(organization: :projects)
    |> Repo.get(id)
    |> Result.from_nillable()
    |> Result.filter_not(fn r -> r.deleted_at end, :deleted)
  end

  def create_resource(attrs) do
    %Resource{}
    |> Resource.create_changeset(attrs)
    |> Repo.insert()
  end

  def add_organization_if_needed(%Resource{} = resource, %User{} = current_user, now) do
    if resource.organization do
      {:ok, resource}
    else
      attrs = %{name: resource.name, contact_email: current_user.email, logo: Faker.Avatar.image_url()}

      Organizations.create_non_personal_organization(attrs, current_user)
      |> Result.flat_map(fn organization ->
        resource
        |> Resource.update_organization_changeset(organization, now)
        |> Repo.update()
        |> Result.flat_map(fn _ -> get_resource(resource.id) end)
      end)
    end
  end

  def add_member_if_needed(%Resource{} = resource, %User{} = current_user) do
    cond do
      !resource.organization -> {:error, :missing_resource_organization}
      Organizations.has_member?(resource.organization, current_user) -> {:ok, resource}
      true -> OrganizationMember.new_member_changeset(resource.organization.id, current_user) |> Repo.insert()
    end
  end

  def update_resource_plan(%Resource{} = resource, attrs, now) do
    resource
    |> Resource.update_plan_changeset(attrs, now)
    |> Repo.update()
  end

  def delete_resource(%Resource{} = resource, now) do
    res =
      resource
      |> Resource.delete_changeset(now)
      |> Repo.update()

    if resource.organization do
      Organizations.delete_organization(resource.organization, now)
    end

    res
  end
end
