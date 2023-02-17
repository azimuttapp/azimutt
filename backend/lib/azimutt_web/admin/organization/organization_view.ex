defmodule AzimuttWeb.Admin.OrganizationView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb
  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link
  alias Azimutt.Organizations.Organization
  alias Azimutt.Services.StripeSrv
  alias Azimutt.Utils.Page
  alias AzimuttWeb.Router.Helpers, as: Routes

  def format_datetime(date) do
    {:ok, formatted} = Timex.format(date, "{Mshort} {D}, {h24}:{m}:{s}")
    formatted
  end

  def format_date_filter(date) do
    {:ok, formatted} = Timex.format(date, "{YYYY}-{0M}-{0D}")
    formatted
  end

  def format_data(data) when is_nil(data), do: ""
  def format_data(%Organization.Data{} = data), do: data |> Map.from_struct() |> Jason.encode!()

  def display_number(list) do
    threshold = Azimutt.config(:free_plan_seats)

    case Enum.count(list) do
      1 -> content_tag(:span, "1")
      x when x <= threshold -> content_tag(:span, x, class: "text-scheme-blue")
      x when x > threshold -> content_tag(:span, x, class: "text-scheme-red")
    end
  end
end
