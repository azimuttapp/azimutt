defmodule AzimuttWeb.Api.ProjectTokenView do
  use AzimuttWeb, :view
  alias Azimutt.Projects.ProjectToken

  def render("index.json", %{tokens: tokens}) do
    render_many(tokens, __MODULE__, "show.json")
  end

  def render("show.json", %{token: %ProjectToken{} = token}) do
    %{
      id: token.id,
      name: token.name,
      nb_access: token.nb_access,
      last_access: token.last_access,
      expire_at: token.expire_at,
      created_at: token.created_at,
      created_by: render_one(token.created_by, AzimuttWeb.Api.UserView, "show.json")
    }
  end
end
