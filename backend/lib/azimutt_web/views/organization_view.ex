defmodule AzimuttWeb.OrganizationView do
  use AzimuttWeb, :view

  def last_update(datetime) do
    {:ok, relative_str} = datetime |> Timex.format("{relative}", :relative)
    relative_str
  end
end
