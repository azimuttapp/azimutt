defmodule AzimuttWeb.Admin.DashboardView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag
  alias Azimutt.Utils.Stringx
  alias AzimuttWeb.Router.Helpers, as: Routes
  # FIXME obligé pour le moment de réaliser les imports ci dessous manuellement dans chaque View Admin.
  # il faudra trouver comment faire avec la nouvelle structure

  def format_value(%NaiveDateTime{} = date), do: date |> Timex.format!("{YYYY}-{0M}-{0D}")
  def format_value(value), do: value
end
