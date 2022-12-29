defmodule AzimuttWeb.Admin.OrganizationView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb

  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link
  alias AzimuttWeb.Router.Helpers, as: Routes

  def format_date(date) do
    {:ok, date_parsed} = Timex.format(date, "{D}/{M}/{YY}")
    date_parsed
  end

  def display_number(list) do
    case Enum.count(list) do
      1 -> content_tag(:span, "1")
      x when x < 4 -> content_tag(:span, x, class: "text-scheme-blue")
      x when x >= 4 -> content_tag(:span, x, class: "text-scheme-red")
    end
  end
end
