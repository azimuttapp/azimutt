defmodule AzimuttWeb.Admin.UserView do
  # use AzimuttWeb, :view
  # use Phoenix.View, root: "lib/azimutt_web/admin/templates", path: "*"
  use Phoenix.View, root: "lib/azimutt_web", namespace: AzimuttWeb
  import Phoenix.HTML.Tag
  import Phoenix.HTML.Link
  alias Azimutt.Accounts.User
  alias Azimutt.Utils.Mapx
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
  def format_data(%User.Data{} = data), do: data |> Map.from_struct() |> Mapx.filter(fn {_, v} -> !is_nil(v) end) |> Jason.encode!()
end
