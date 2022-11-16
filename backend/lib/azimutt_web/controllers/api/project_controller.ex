defmodule AzimuttWeb.Api.ProjectController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias AzimuttWeb.Utils.CtxParams
  action_fallback AzimuttWeb.Api.FallbackController

  swagger_path :index do
    get("/api/v1/projects")
    summary("Query for projects")
    description("Query for projects. This operation supports with paging and filtering")
    produces("application/json")
    tag("Projects")

    response(200, "OK", Schema.ref(:Projects))
    response(400, "Client Error")
  end

  def index(conn, %{"organization_id" => organization_id}) do
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user),
         do: conn |> render("index.json", projects: organization.projects)
  end

  def show(conn, %{"organization_id" => _organization_id, "id" => id} = params) do
    ctx = CtxParams.from_params(params)
    current_user = conn.assigns.current_user

    with {:ok, %Project{} = project} <- Projects.get_project(id, current_user),
         do: conn |> render("show.json", project: project, ctx: ctx)
  end

  swagger_path :create do
    post("/api/v1/organizations/:organization_id/projects")
    summary("Create a project")
    description("TODO")
    produces("application/json")
    tag("Projects")

    response(201, "Created")
    response(400, "Client Error")
  end

  def create(conn, %{"organization_id" => organization_id} = project_params) do
    ctx = CtxParams.from_params(project_params)
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user),
         {:ok, %Project{} = created} <- Projects.create_project(project_params, organization, current_user),
         # needed to get preloads
         {:ok, %Project{} = project} <- Projects.get_project(created.id, current_user),
         do: conn |> put_status(:created) |> render("show.json", project: project, ctx: ctx)
  end

  def update(conn, %{"organization_id" => _organization_id, "id" => id} = project_params) do
    now = DateTime.utc_now()
    ctx = CtxParams.from_params(project_params)
    current_user = conn.assigns.current_user

    with {:ok, %Project{} = project} <- Projects.get_project(id, current_user),
         {:ok, %Project{} = updated} <- Projects.update_project(project, project_params, current_user, now),
         # needed to get preloads
         {:ok, %Project{} = project} <- Projects.get_project(updated.id, current_user),
         do: conn |> render("show.json", project: project, ctx: ctx)
  end

  def delete(conn, %{"organization_id" => _organization_id, "id" => id}) do
    current_user = conn.assigns.current_user

    with {:ok, %Project{} = project} <- Projects.get_project(id, current_user),
         {:ok, %Project{}} <- Projects.delete_project(project, current_user),
         do: conn |> send_resp(:no_content, "")
  end

  def swagger_definitions do
    %{
      Project:
        swagger_schema do
          title("Project")
          description("An Azimutt project")

          properties do
            name(:string, "Project name", required: true)
            id(:string, "Unique identifier", required: true)
            slug(:string, "Project slug")
          end

          example(%{
            name: "Project name",
            id: "123",
            slug: "project-name"
          })
        end,
      Projects:
        swagger_schema do
          title("Projects")
          description("A collection of Projects")
          type(:array)
          items(Schema.ref(:Project))
        end
    }
  end
end
