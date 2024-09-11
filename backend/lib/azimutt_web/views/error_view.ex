defmodule AzimuttWeb.ErrorView do
  use AzimuttWeb, :view
  require Logger
  alias Plug.Conn.Status

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.html", _assigns) do
  #   "Internal Server Error"
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  def render("error.json", %{conn: conn} = params) do
    response =
      params
      |> Map.delete(:conn)
      # set from UserAuth.fetch_current_user
      |> Map.delete(:current_user)
      # set from UserAuth.fetch_clever_cloud_resource
      |> Map.delete(:clever_cloud)
      # set from UserAuth.fetch_heroku_resource
      |> Map.delete(:heroku)
      |> Map.merge(%{
        statusCode: conn.status,
        error: Status.reason_phrase(conn.status)
      })

    try do
      response |> Jason.encode!() |> Jason.decode!()
    rescue
      e ->
        Logger.error("ErrorView.render(\"error.json\"): Failed to encode error response: #{inspect(e)}")
        Logger.error("response: #{inspect(response)}")

        %{
          statusCode: 500,
          error: "Internal Server Error",
          message: "Failed to generate error response"
        }
    end
  end
end
