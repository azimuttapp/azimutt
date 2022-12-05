defmodule AzimuttWeb.Api.HerokuView do
  use AzimuttWeb, :view

  def render("show.json", %{resource: resource, message: message}) do
    %{id: resource.heroku_id, message: message}
  end
end
