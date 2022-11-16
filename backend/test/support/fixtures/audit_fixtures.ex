defmodule Azimutt.AuditFixtures do
  @moduledoc false
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project

  def project_created_fixture(%User{} = user, %Organization{} = organization, %Project{} = project) do
    {:ok, event} = Azimutt.Audit.project_created(user, organization.id, project.id)
    event
  end
end
