defmodule AzimuttWeb.Admin.ProjectView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb

  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link

  def format_date(date) do
    {:ok, date_parsed} = Timex.format(date, "{D}/{M}/{YY}")
    date_parsed
  end
end
