defmodule Azimutt.Admin do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Tracking.Event
  alias Azimutt.Repo

  def list_organizations do
    Organization
    |> preload(:members)
    |> preload(:projects)
    |> preload(:invitations)
    |> Repo.all()
  end

  def list_users do
    User
    |> preload(:organizations)
    |> Repo.all()
    |> List.first()
  end

  def list_last_events(number) do
    Event
    |> preload(:project)
    |> preload(:organization)
    |> preload(:created_by)
    |> Repo.all()
    |> Enum.take(number)
  end

  def cli_display_event(number) do
    header = ["Created at", "Event", "ID", "Created By"]

    rows =
      for event <- list_last_events(number) do
        [event.created_at, event.name, event.id, event.created_by.name]
      end

    TableRex.quick_render!(rows, header)
    |> IO.puts()
  end
end
