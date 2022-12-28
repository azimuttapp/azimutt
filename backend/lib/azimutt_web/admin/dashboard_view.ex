defmodule AzimuttWeb.Admin.DashboardView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb

  def display_project_name(event) do
    if event.project !== nil do
      event.project.name
    else
      " - "
    end
  end

  def display_organization_name(event) do
    if event.organization !== nil do
      event.organization.name
    else
      " - "
    end
  end
end
