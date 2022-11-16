defmodule Azimutt.Audit do
  @moduledoc "The Audit context."
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Audit.Event
  alias Azimutt.Repo

  def list_events do
    Repo.all(Event)
  end

  def project_loaded(%User{} = current_user, organization_id, project_id) do
    create_event(:project_loaded, current_user, organization_id, project_id)
  end

  def project_created(%User{} = current_user, organization_id, project_id) do
    create_event(:project_created, current_user, organization_id, project_id)
  end

  def project_updated(%User{} = current_user, organization_id, project_id) do
    create_event(:project_updated, current_user, organization_id, project_id)
  end

  def project_deleted(%User{} = current_user, organization_id, project_id) do
    create_event(:project_deleted, current_user, organization_id, project_id)
  end

  defp create_event(name, %User{} = current_user, organization_id \\ nil, project_id \\ nil) do
    %Event{}
    |> Event.changeset(%{
      name: name,
      created_by: current_user,
      organization_id: organization_id,
      project_id: project_id
    })
    |> Repo.insert()
  end
end
