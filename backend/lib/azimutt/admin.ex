defmodule Azimutt.Admin do
  @moduledoc "The Admin context."
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Heroku
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Page
  alias Azimutt.Utils.Result

  def count_users, do: User |> Repo.aggregate(:count, :id)
  def count_organizations, do: Organization |> Repo.aggregate(:count, :id)
  def count_personal_organizations, do: Organization |> where([o], o.is_personal == true) |> Repo.aggregate(:count, :id)
  def count_non_personal_organizations, do: Organization |> where([o], o.is_personal == false) |> Repo.aggregate(:count, :id)
  def count_stripe_subscriptions, do: Organization |> where([o], not is_nil(o.stripe_subscription_id)) |> Repo.aggregate(:count, :id)
  def count_heroku_resources, do: Heroku.Resource |> Repo.aggregate(:count, :id)
  def count_projects, do: Project |> Repo.aggregate(:count, :id)

  def list_users(%Page.Info{} = p) do
    User |> Page.get(p)
  end

  def get_user(id) do
    User
    |> where([u], u.id == ^id)
    |> preload(organizations: [:heroku_resource, :created_by, :members, projects: [:organization]])
    |> Repo.one()
    |> Result.from_nillable()
  end

  def list_organizations(%Page.Info{} = p) do
    Organization
    |> preload(:members)
    |> preload(:projects)
    |> preload(:invitations)
    |> preload(:heroku_resource)
    |> preload(:created_by)
    |> Page.get(p)
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

  def list_projects(%Page.Info{} = p) do
    Project
    |> preload(:organization)
    |> preload(:created_by)
    |> Page.get(p)
  end

  def get_project(id) do
    Project
    |> where([p], p.id == ^id)
    |> preload(:created_by)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def list_events(%Page.Info{} = p) do
    query_events()
    |> Page.get(p)
  end

  def get_event(id) do
    query_events()
    |> where([e], e.id == ^id)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def get_user_events(%User{} = user, %Page.Info{} = p) do
    query_events()
    |> where([e], e.created_by_id == ^user.id)
    |> Page.get(p)
  end

  def get_day_user_events(%User{} = user, date, %Page.Info{} = p) do
    {:ok, day} = date |> Timex.format("{YYYY}-{0M}-{0D}")

    query_events()
    |> where([e], e.created_by_id == ^user.id and fragment("to_char(?, 'yyyy-mm-dd')", e.created_at) == ^day)
    |> Page.get(p)
  end

  def get_organization_events(%Organization{} = organization, %Page.Info{} = p) do
    query_events()
    |> where([e], e.organization_id == ^organization.id)
    |> Page.get(p)
  end

  def get_project_events(%Project{} = project, %Page.Info{} = p) do
    query_events()
    |> where([e], e.project_id == ^project.id)
    |> Page.get(p)
  end

  defp query_events do
    Event
    |> preload(:project)
    |> preload(:organization)
    |> preload(:created_by)
  end

  def daily_created_users, do: User |> daily_creations()
  def daily_created_projects, do: Project |> daily_creations()
  def daily_created_non_personal_organizations, do: Organization |> where([o], o.is_personal == false) |> daily_creations()

  defp daily_creations(query) do
    query
    |> select([t], {fragment("to_char(?, 'yyyy-mm-dd')", t.created_at), count(t.id, :distinct)})
    |> group_by([t], fragment("to_char(?, 'yyyy-mm-dd')", t.created_at))
    |> order_by([t], fragment("to_char(?, 'yyyy-mm-dd')", t.created_at))
    |> Repo.all()
  end

  def daily_connected_users do
    Event
    |> select([e], {fragment("to_char(?, 'yyyy-mm-dd')", e.created_at), count(e.created_by_id, :distinct)})
    |> daily_events()
  end

  def daily_used_projects do
    Event
    |> where([e], not is_nil(e.project_id))
    |> select([e], {fragment("to_char(?, 'yyyy-mm-dd')", e.created_at), count(e.project_id, :distinct)})
    |> daily_events()
  end

  def daily_event(name) do
    Event
    |> where([e], e.name == ^name)
    |> select([e], {fragment("to_char(?, 'yyyy-mm-dd')", e.created_at), count()})
    |> daily_events()
  end

  defp daily_events(query) do
    query
    |> group_by([e], fragment("to_char(?, 'yyyy-mm-dd')", e.created_at))
    |> order_by([e], fragment("to_char(?, 'yyyy-mm-dd')", e.created_at))
    |> Repo.all()
  end

  def monthly_connected_users do
    Event
    |> select([e], {fragment("to_char(?, 'yyyy-mm')", e.created_at), count(e.created_by_id, :distinct)})
    |> monthly_events()
  end

  def monthly_used_projects do
    Event
    |> where([e], not is_nil(e.project_id))
    |> select([e], {fragment("to_char(?, 'yyyy-mm')", e.created_at), count(e.project_id, :distinct)})
    |> monthly_events()
  end

  defp monthly_events(query) do
    query
    |> group_by([e], fragment("to_char(?, 'yyyy-mm')", e.created_at))
    |> order_by([e], fragment("to_char(?, 'yyyy-mm')", e.created_at))
    |> Repo.all()
  end

  def daily_user_activity(%User{} = user), do: Event |> where([o], o.created_by_id == ^user.id) |> get_activity()
  def daily_organization_activity(%Organization{} = org), do: Event |> where([o], o.organization_id == ^org.id) |> get_activity()
  def daily_project_activity(%Project{} = project), do: Event |> where([o], o.project_id == ^project.id) |> get_activity()

  defp get_activity(query) do
    query
    |> group_by([e], fragment("to_char(?, 'yyyy-mm-dd')", e.created_at))
    |> select([e], {fragment("to_char(?, 'yyyy-mm-dd')", e.created_at), count()})
    |> order_by([e], fragment("to_char(?, 'yyyy-mm-dd')", e.created_at))
    |> Repo.all()
  end
end
