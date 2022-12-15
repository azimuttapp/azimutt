defmodule Azimutt.Heroku do
  @moduledoc "Context for the Heroku addon"
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Heroku.Resource
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Repo
  alias Azimutt.Utils.Result

  def app_addons_url(app), do: "https://dashboard.heroku.com/apps/#{app}/resources"
  def app_settings_url(app), do: "https://dashboard.heroku.com/apps/#{app}/settings"

  def allowed_members(plan) do
    team_members = Regex.named_captures(~r/team-(?<members>[0-9]+)/, plan)

    if team_members do
      String.to_integer(team_members["members"])
    else
      Azimutt.config(:free_plan_seats)
    end
  end

  # use only for HerokuController.index local helper
  def all_resources do
    Resource
    |> preload(:organization)
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
    %Resource{}
    |> Resource.create_changeset(attrs)
    |> Repo.insert()
  end

  def add_organization_if_needed(%Resource{} = resource, %User{} = current_user, now) do
    if resource.organization do
      {:ok, resource.organization}
    else
      attrs = %{name: resource.name, contact_email: current_user.email, logo: Faker.Avatar.image_url()}

      Organizations.create_non_personal_organization(attrs, current_user)
      |> Result.flat_tap(fn organization ->
        resource
        |> Resource.update_organization_changeset(organization, now)
        |> Repo.update()
      end)
    end
  end

  def add_member_if_needed(%Resource{} = resource, %Organization{} = organization, %User{} = current_user) do
    slots_in_plan = allowed_members(resource.plan)
    existing_members = Organizations.count_member(organization)

    cond do
      existing_members > slots_in_plan ->
        {:error, :too_many_members}

      Organizations.has_member?(organization, current_user) ->
        {:ok, :already_member}

      existing_members < slots_in_plan ->
        OrganizationMember.new_member_changeset(organization.id, current_user)
        |> Repo.insert()
        |> Result.map(fn _ -> :member_added end)

      true ->
        {:error, :member_limit_reached}
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
