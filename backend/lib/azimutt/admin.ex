defmodule Azimutt.Admin do
  @moduledoc "The Admin context."
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Heroku
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result

  def count_users, do: User |> Repo.aggregate(:count, :id)
  def count_organizations, do: Organization |> Repo.aggregate(:count, :id)
  def count_personal_organizations, do: Organization |> where([o], o.is_personal == true) |> Repo.aggregate(:count, :id)
  def count_non_personal_organizations, do: Organization |> where([o], o.is_personal == false) |> Repo.aggregate(:count, :id)
  def count_stripe_subscriptions, do: Organization |> where([o], not is_nil(o.stripe_subscription_id)) |> Repo.aggregate(:count, :id)
  def count_heroku_resources, do: Heroku.Resource |> Repo.aggregate(:count, :id)
  def count_projects, do: Project |> Repo.aggregate(:count, :id)

  # FIXME add pagination instead of limit
  def list_users(limit) do
    User
    |> order_by(desc: :created_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_user(id) do
    User
    |> where([u], u.id == ^id)
    |> preload(organizations: [:heroku_resource, :created_by, :members, projects: [:organization]])
    |> Repo.one()
    |> Result.from_nillable()
  end

  def list_organizations(limit) do
    Organization
    |> order_by(desc: :created_at)
    |> limit(^limit)
    |> preload(:members)
    |> preload(:projects)
    |> preload(:invitations)
    |> preload(:heroku_resource)
    |> preload(:created_by)
    |> Repo.all()
  end

  def get_organization(id) do
    Organization
    |> where([o], o.id == ^id)
    |> preload(members: [:user, :created_by, :updated_by])
    |> preload(projects: [:organization])
    |> preload(:heroku_resource)
    |> preload(:invitations)
    |> preload(:created_by)
    |> preload(:updated_by)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def list_projects(limit) do
    Project
    |> order_by(desc: :created_at)
    |> limit(^limit)
    |> preload(:organization)
    |> preload(:created_by)
    |> Repo.all()
  end

  def get_project(id) do
    Project
    |> where([p], p.id == ^id)
    |> order_by(desc: :created_at)
    |> preload(:created_by)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def list_events(limit) do
    query_events()
    |> limit(^limit)
    |> Repo.all()
  end

  def get_event(id) do
    query_events()
    |> where([e], e.id == ^id)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def get_user_events(id, limit) do
    query_events()
    |> where([e], e.created_by_id == ^id)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_organization_events(id, limit) do
    query_events()
    |> where([e], e.organization_id == ^id)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_project_events(id, limit) do
    query_events()
    |> where([e], e.project_id == ^id)
    |> limit(^limit)
    |> Repo.all()
  end

  defp query_events do
    Event
    |> preload(:project)
    |> preload(:organization)
    |> preload(:created_by)
    |> order_by(desc: :created_at)
  end
end
