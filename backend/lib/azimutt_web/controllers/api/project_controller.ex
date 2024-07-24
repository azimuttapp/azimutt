defmodule AzimuttWeb.Api.ProjectController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias AzimuttWeb.Utils.CtxParams
  alias AzimuttWeb.Utils.SwaggerCommon
  import AzimuttWeb.Utils.ControllerHelpers, only: [for_writers_api: 4]
  action_fallback AzimuttWeb.Api.FallbackController

  swagger_path :index do
    tag("Projects")
    summary("List organization projects")
    description("Get the list of all projects in the organization.")
    get("#{SwaggerCommon.organization_path()}/projects")
    SwaggerCommon.authorization()
    SwaggerCommon.organization_params()

    response(200, "OK", Schema.ref(:Projects))
    response(400, "Client Error")
  end

  def index(conn, %{"organization_organization_id" => organization_id}) do
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user),
         do: conn |> render("index.json", projects: organization.projects, current_user: current_user)
  end

  swagger_path :show do
    tag("Projects")
    summary("Get a project")
    description("Fetch the required project.")
    get(SwaggerCommon.project_path())
    SwaggerCommon.authorization()
    SwaggerCommon.project_params()

    response(200, "OK", Schema.ref(:Project))
    response(400, "Client Error")
  end

  def show(conn, %{"organization_id" => _organization_id, "project_id" => project_id} = params) do
    {now, maybe_current_user, ctx} = {DateTime.utc_now(), conn.assigns.current_user, CtxParams.from_params(params)}

    with {:ok, %Project{} = project} <- Projects.load_project(project_id, maybe_current_user, params["token"], now),
         do: conn |> render("show.json", project: project, maybe_current_user: maybe_current_user, ctx: ctx)
  end

  def create(conn, %{"organization_organization_id" => organization_id} = params) do
    current_user = conn.assigns.current_user
    ctx = CtxParams.from_params(params)

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user),
         {:ok, %Project{} = created} <- Projects.create_project(params, organization, current_user),
         # needed to get preloads
         {:ok, %Project{} = project} <- Projects.get_project(created.id, current_user),
         do: conn |> put_status(:created) |> render("show.json", project: project, maybe_current_user: current_user, ctx: ctx)
  end

  def update(conn, %{"organization_organization_id" => org_id, "project_id" => project_id} = params) do
    {now, current_user, ctx} = {DateTime.utc_now(), conn.assigns.current_user, CtxParams.from_params(params)}
    {:ok, %Organization{} = organization} = Organizations.get_organization(org_id, current_user)

    for_writers_api(conn, organization, current_user, fn ->
      with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
           {:ok, %Project{} = updated} <- Projects.update_project(project, params, current_user, now),
           # needed to get preloads
           {:ok, %Project{} = project} <- Projects.get_project(updated.id, current_user),
           do: conn |> render("show.json", project: project, maybe_current_user: current_user, ctx: ctx)
    end)
  end

  def delete(conn, %{"organization_organization_id" => _organization_id, "project_id" => project_id}) do
    current_user = conn.assigns.current_user

    with {:ok, %Project{} = project} <- Projects.get_project(project_id, current_user),
         {:ok, %Project{}} <- Projects.delete_project(project, current_user),
         do: conn |> send_resp(:no_content, "")
  end

  def swagger_definitions do
    %{
      Project:
        swagger_schema do
          description("An Azimutt project")

          properties do
            id(:string, "Unique identifier", required: true, example: "a2cf8a87-0316-40eb-98ce-72659dae9420")
            slug(:string, "Project slug", required: true, example: "azimutt-dev")
            name(:string, "Project name", required: true, example: "Azimutt dev")
            description(:string, "Project description", example: "Explore the Azimutt local database")
            encoding_version(:integer, "Project storage version", required: true, example: 2)
            storage_kind(:string, "Project storage kind", enum: ["local", "remote"], required: true, example: "local")
            visibility(:string, "If the project is publicly visible", enum: ["none", "read", "write"], required: true, example: "read")
            nb_sources(:integer, "Number of sources in the project", required: true, example: 2)
            nb_tables(:integer, "Number of tables in the project", required: true, example: 563)
            nb_columns(:integer, "Number of columns in the project", required: true, example: 13_945)
            nb_relations(:integer, "Number of relations in the project", required: true, example: 2524)
            nb_types(:integer, "Number of custom types in the project", required: true, example: 4)
            nb_comments(:integer, "Number of SQL comments in the project", required: true, example: 892)
            nb_layouts(:integer, "Number of layouts in the project", required: true, example: 32)
            nb_notes(:integer, "Number of notes in the project", required: true, example: 3264)
            nb_memos(:integer, "Number of memos in the project", required: true, example: 183)
            created_at(:string, "When the project was created", format: "date-time", required: true, example: "2023-05-12T06:56:41.467400Z")
            updated_at(:string, "The last time the project was updated", format: "date-time", required: true, example: "2023-06-28T14:43:12.345289Z")
            archived_at(:string, "When the project was archived", format: "date-time", example: "2024-01-07T07:55:12.174780Z")
          end
        end,
      Projects:
        swagger_schema do
          description("A collection of Projects")
          type(:array)
          items(Schema.ref(:Project))
        end
    }
  end
end
