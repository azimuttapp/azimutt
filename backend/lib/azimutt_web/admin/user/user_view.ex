defmodule AzimuttWeb.Admin.UserView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb

  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link
  alias AzimuttWeb.Router.Helpers, as: Routes

  def format_date(date) do
    {:ok, date_parsed} = Timex.format(date, "{D}/{M}/{YY} à {h24}h{m}")
    date_parsed
  end
end
