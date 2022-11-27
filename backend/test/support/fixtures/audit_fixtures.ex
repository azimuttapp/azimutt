defmodule Azimutt.TrackingFixtures do
  @moduledoc false
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project

  def project_created_fixture(%User{} = user, %Organization{} = organization, %Project{} = project) do
    {:ok, event} = Azimutt.Tracking.project_created(user, organization.id, project.id)
    event
  end
end
