defmodule AzimuttWeb.Admin.EventView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb
  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link
  alias Azimutt.Utils.Nil
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

  def format_details(details) when is_nil(details), do: ""
  def format_details(details), do: details |> Jason.encode!()
end
