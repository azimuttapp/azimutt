defmodule AzimuttWeb.Api.UserController do
  use AzimuttWeb, :controller
  use PhoenixSwagger
  alias AzimuttWeb.Utils.SwaggerCommon
  action_fallback AzimuttWeb.Api.FallbackController

  swagger_path :current do
    tag("Users")
    summary("Get the current user")
    description("Fetch the user which is logged in.")
    get("/users/current")
    SwaggerCommon.authorization()

    response(200, "OK", Schema.ref(:User))
    response(400, "Client Error")
  end

  def current(conn, _params) do
    current_user = conn.assigns.current_user
    conn |> render("show.json", user: current_user)
  end

  def swagger_definitions do
    %{
      User:
        swagger_schema do
          description("An User in Azimutt")

          properties do
            id(:string, "Unique identifier", format: "uuid", required: true, example: "11bd9544-d56a-43d7-9065-6f1f25addf8a")
            slug(:string, "User slug", required: true, example: "loic-knuchel")
            name(:string, "User name", required: true, example: "Loïc Knuchel")
            email(:string, "User email", format: "email", required: true, example: "loic@azimutt.app")
            avatar(:string, "User avatar", format: "uri", required: true, example: "https://avatars.githubusercontent.com/u/653009")
            github_username(:string, "User github", example: "loicknuchel")
            twitter_username(:string, "User twitter", example: "loicknuchel")
            is_admin(:boolean, "If the user has admin rights", required: true, example: false)
            last_signin(:string, "Last time the user signed in", format: "date-time", required: true, example: "2024-01-07T08:34:29.582485Z")
            created_at(:string, "When the user was created", format: "date-time", required: true, example: "2023-04-27T17:55:11.612429Z")
          end
        end
    }
  end
end
