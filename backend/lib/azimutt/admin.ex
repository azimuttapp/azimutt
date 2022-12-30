defmodule Azimutt.Admin do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result

  def list_organizations do
    Organization
    |> order_by(desc: :created_at)
    |> preload(:members)
    |> preload(:projects)
    |> preload(:invitations)
    |> preload(:created_by)
    |> Repo.all()
  end

  def list_projects do
    Project
    |> order_by(desc: :created_at)
    |> preload(:created_by)
    |> Repo.all()
  end

  def list_users do
    User
    |> order_by(desc: :created_at)
    |> Repo.all()
  end

  def list_last_events do
    query_events()
    |> Repo.all()
  end

  def list_last_events(number) do
    query_events()
    |> limit(^number)
    |> Repo.all()
  end

  defp query_events do
    Event
    |> preload(:project)
    |> preload(:organization)
    |> preload(:created_by)
    |> order_by(desc: :created_at)
  end

  def get_event(id) do
    query_events()
    |> where([e], e.id == ^id)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def get_organization(id) do
    Organization
    |> where([o], o.id == ^id)
    |> preload(members: [:user, :created_by, :updated_by])
    |> preload(:projects)
    |> preload(:heroku_resource)
    |> preload(:invitations)
    |> preload(:created_by)
    |> preload(:updated_by)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def get_user(id) do
    User
    |> where([u], u.id == ^id)
    |> preload(organizations: [:created_by, :members, projects: [:organization]])
    |> Repo.one()
    |> Result.from_nillable()
  end

  def get_user_events(id) do
    Event
    |> where([e], e.created_by_id == ^id)
    |> order_by(desc: :created_at)
    |> preload(:project)
    |> preload(:organization)
    |> preload(:created_by)
    |> Repo.all()
  end
end
