defmodule AzimuttWeb.Admin.ProjectView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb
  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link
  alias Azimutt.Utils.Page
  alias AzimuttWeb.Router.Helpers, as: Routes

  def format_datetime(date) do
    {:ok, formatted} = Timex.format(date, "{Mshort} {D}, {h24}:{m}:{s}")
    formatted
  end
end
