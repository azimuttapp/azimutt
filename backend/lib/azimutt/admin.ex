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
    User
    |> order_by(desc: :created_at)
    |> Page.get(p)
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
    |> order_by(desc: :created_at)
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
    |> order_by(desc: :created_at)
    |> preload(:organization)
    |> preload(:created_by)
    |> Page.get(p)
  end

  def get_project(id) do
    Project
    |> where([p], p.id == ^id)
    |> order_by(desc: :created_at)
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

  def get_user_events(id, %Page.Info{} = p) do
    query_events()
    |> where([e], e.created_by_id == ^id)
    |> Page.get(p)
  end

  def get_organization_events(id, %Page.Info{} = p) do
    query_events()
    |> where([e], e.organization_id == ^id)
    |> Page.get(p)
  end

  def get_project_events(id, %Page.Info{} = p) do
    query_events()
    |> where([e], e.project_id == ^id)
    |> Page.get(p)
  end

  defp query_events do
    Event
    |> preload(:project)
    |> preload(:organization)
    |> preload(:created_by)
    |> order_by(desc: :created_at)
  end

  def daily_created_users do
    from(User)
    |> group_by([u], fragment("to_char(?, 'yyyy-mm-dd')", u.created_at))
    |> select([u], {fragment("to_char(?, 'yyyy-mm-dd')", u.created_at), count(u.id)})
    |> order_by([u], fragment("to_char(?, 'yyyy-mm-dd')", u.created_at))
    |> Repo.all()
  end

  def daily_created_projects do
    from(Project)
    |> group_by([p], fragment("to_char(?, 'yyyy-mm-dd')", p.created_at))
    |> select([p], {fragment("to_char(?, 'yyyy-mm-dd')", p.created_at), count(p.id)})
    |> order_by([p], fragment("to_char(?, 'yyyy-mm-dd')", p.created_at))
    |> Repo.all()
  end

  def daily_created_non_personal_organizations do
    from(Organization)
    |> where([o], o.is_personal == false)
    |> group_by([o], fragment("to_char(?, 'yyyy-mm-dd')", o.created_at))
    |> select([o], {fragment("to_char(?, 'yyyy-mm-dd')", o.created_at), count(o.id)})
    |> order_by([o], fragment("to_char(?, 'yyyy-mm-dd')", o.created_at))
    |> Repo.all()
  end

  def daily_connected_users do
    from(Event)
    |> group_by([e], fragment("to_char(?, 'yyyy-mm-dd')", e.created_at))
    |> select([e], {fragment("to_char(?, 'yyyy-mm-dd')", e.created_at), count(e.created_by_id, :distinct)})
    |> order_by([e], fragment("to_char(?, 'yyyy-mm-dd')", e.created_at))
    |> Repo.all()
  end

  def monthly_connected_users do
    from(Event)
    |> group_by([e], fragment("to_char(?, 'yyyy-mm')", e.created_at))
    |> select([e], {fragment("to_char(?, 'yyyy-mm')", e.created_at), count(e.created_by_id, :distinct)})
    |> order_by([e], fragment("to_char(?, 'yyyy-mm')", e.created_at))
    |> Repo.all()
  end

  def daily_used_projects do
    from(Event)
    |> where([o], not is_nil(o.project_id))
    |> group_by([e], fragment("to_char(?, 'yyyy-mm-dd')", e.created_at))
    |> select([e], {fragment("to_char(?, 'yyyy-mm-dd')", e.created_at), count(e.project_id, :distinct)})
    |> order_by([e], fragment("to_char(?, 'yyyy-mm-dd')", e.created_at))
    |> Repo.all()
  end

  def monthly_used_projects do
    from(Event)
    |> where([o], not is_nil(o.project_id))
    |> group_by([e], fragment("to_char(?, 'yyyy-mm')", e.created_at))
    |> select([e], {fragment("to_char(?, 'yyyy-mm')", e.created_at), count(e.project_id, :distinct)})
    |> order_by([e], fragment("to_char(?, 'yyyy-mm')", e.created_at))
    |> Repo.all()
  end
end
