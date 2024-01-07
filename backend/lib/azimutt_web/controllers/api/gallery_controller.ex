defmodule AzimuttWeb.Api.GalleryController do
  use AzimuttWeb, :controller
  alias Azimutt.Gallery
  action_fallback AzimuttWeb.Api.FallbackController

  def index(conn, _params) do
    conn |> render("index.json", samples: Gallery.list_samples())
  end
end
