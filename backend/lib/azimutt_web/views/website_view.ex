defmodule AzimuttWeb.WebsiteView do
  use AzimuttWeb, :view
  import AzimuttWeb.Components.Brand
  alias Azimutt.Accounts.User
  alias Azimutt.Utils.Enumx
  alias Azimutt.Utils.Result

  def user_organization(%User{} = user, organization_id) do
    user.members
    |> Enum.map(fn m -> m.organization end)
    |> Enum.find(fn o -> o.id == organization_id end)
    |> Result.from_nillable()
  end

  def user_project(%User{} = user, project_id) do
    user.members
    |> Enum.map(fn m -> m.organization end)
    |> Enum.flat_map(fn o ->
      o.projects
      |> Enum.filter(fn p -> p.id == project_id end)
      |> Enum.map(fn p -> {o, p} end)
    end)
    |> Enumx.one()
  end
end
