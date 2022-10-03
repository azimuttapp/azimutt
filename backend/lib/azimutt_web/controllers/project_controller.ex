defmodule AzimuttWeb.ProjectController do
  use AzimuttWeb, :controller
  # alias Azimutt.Organizations
  # alias Azimutt.Projects

  # FIXME: doesn't work, not sure where it should be used :(
  # def index(conn, %{"organization_id" => organization_id}) do
  #   current_user = conn.assigns.current_user
  #   {:ok, organization} = Organizations.get_organization(organization_id, current_user)
  #   projects = Projects.list_projects(organization, current_user)
  #   render(conn, "index.html", projects: projects)
  # end
end
