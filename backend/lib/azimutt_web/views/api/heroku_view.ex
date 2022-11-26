defmodule AzimuttWeb.Api.HerokuView do
  use AzimuttWeb, :view

  def render("index.json", _params) do
    %{ok: "ok"}
  end
end
