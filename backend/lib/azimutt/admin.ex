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

  def list_organizations do
    Organization
    |> preload(:members)
    |> preload(:projects)
    |> preload(:invitations)
    |> preload(:created_by)
    |> Repo.all()
  end

  def list_projects do
    Project
    |> preload(:created_by)
    |> Repo.all()
  end

  def list_users do
    User
    |> Repo.all()
  end

  def list_last_events do
    query_events()
    |> Repo.all()
  end

  def list_last_events(number) do
    query_events()
    |> Repo.all()
    |> Enum.take(number)
  end

  defp query_events do
    Event
    |> preload(:project)
    |> preload(:organization)
    |> preload(:created_by)
  end

  def cli_display(list) do
    header = ["Created at", "name", "ID", "Created By"]

    rows =
      for element <- list do
        [element.created_at, element.name, element.id, element.created_by.name]
      end

    TableRex.quick_render!(rows, header)
    |> IO.puts()
  end
end
