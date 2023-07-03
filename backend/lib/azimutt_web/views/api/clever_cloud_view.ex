defmodule AzimuttWeb.Api.CleverCloudView do
  use AzimuttWeb, :view

  def render("show.json", %{resource: resource, message: message}) do
    %{id: resource.id, config: %{}, message: message}
  end
end
