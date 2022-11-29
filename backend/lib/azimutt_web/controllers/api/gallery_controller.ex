defmodule AzimuttWeb.Api.GalleryController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias Azimutt.Gallery
  action_fallback AzimuttWeb.Api.FallbackController

  swagger_path :index do
    get("/api/v1/gallery")
    summary("List sample projects")
    description("List sample projects")
    produces("application/json")
    tag("Samples")

    response(200, "OK", Schema.ref(:Samples))
    response(400, "Client Error")
  end

  def index(conn, _params) do
    conn |> render("index.json", samples: Gallery.list_samples())
  end

  def swagger_definitions do
    %{
      Sample:
        swagger_schema do
          title("Sample")
          description("A Sample project")

          properties do
            slug(:string, "Sample slug", required: true)
            color(:string, "Sample color", required: true)
            icon(:string, "Sample icon", required: true)
            name(:string, "Project name", required: true)
            description(:string, "Project description", required: true)
            project_id(:string, "Project id", required: true)
            nb_tables(:integer, "Nb project tables", required: true)
          end
        end,
      Samples:
        swagger_schema do
          title("Samples")
          description("A collection of Samples")
          type(:array)
          items(Schema.ref(:Sample))
        end
    }
  end
end
