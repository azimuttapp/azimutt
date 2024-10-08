defmodule Azimutt.CleverCloud do
  @moduledoc "Context for the Clever Cloud addon"
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.CleverCloud.Resource
  alias Azimutt.Organizations
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Repo
  alias Azimutt.Utils.Result

  def org_url(org), do: "https://console.clever-cloud.com/organisations/#{org}"
  def addon_url(org, addon), do: "https://console.clever-cloud.com/organisations/#{org}/addons/#{addon}"
  def addon_settings_url(org, addon), do: "https://console.clever-cloud.com/organisations/#{org}/addons/#{addon}/informations"

  # use only for CleverCloudController.index local helper
  def all_resources do
    Resource
    |> order_by([r], desc: [r.deleted_at, r.created_at])
    |> preload(organization: [:projects])
    |> Repo.all()
  end

  def get_resource(id) do
    Resource
    |> preload(:organization)
    |> Repo.get(id)
    |> Result.from_nillable()
    |> Result.filter_not(fn r -> r.deleted_at end, :deleted)
  end

  def create_resource(attrs) do
    # Can't create organization here because of the `current_user` need :/
    %Resource{}
    |> Resource.create_changeset(attrs)
    |> Repo.insert()
  end

  def set_organization_if_needed(%Resource{} = resource, %User{} = current_user, now) do
    if resource.organization do
      {:ok, resource}
    else
      attrs = %{name: resource.owner_name, logo: Faker.Avatar.image_url()}

      Organizations.create_non_personal_organization(attrs, current_user)
      |> Result.flat_map(fn organization ->
        resource
        |> Resource.update_organization_changeset(organization, now)
        |> Repo.update()
      end)
      |> Result.flat_map(fn _ -> get_resource(resource.id) end)
    end
  end

  def add_member_if_needed(%Resource{} = resource, %User{} = current_user) do
    existing_members = Organizations.count_member(resource.organization)

    cond do
      Organizations.has_member?(resource.organization, current_user) ->
        {:ok, :already_member}

      existing_members < resource.organization.plan_seats ->
        OrganizationMember.new_member_changeset(resource.organization.id, current_user, nil)
        |> Repo.insert()
        |> Result.map(fn _ -> :member_added end)

      existing_members > resource.organization.plan_seats ->
        {:error, :too_many_members, resource}

      true ->
        {:error, :member_limit_reached, resource}
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

    # FIXME: keep this???
    if resource.organization do
      Organizations.delete_organization(resource.organization, now)
    end

    res
  end
end
