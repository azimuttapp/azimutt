defmodule AzimuttWeb.StartChecklistController do
  use AzimuttWeb, :controller
  alias Azimutt.Services.OnboardingSrv
  alias Azimutt.Utils.Result

  def check(conn, %{"organization_organization_id" => organization_id, "item" => item}) do
    current_user = conn.assigns.current_user

    OnboardingSrv.add_item(current_user, item)
    |> Result.map(fn _ -> conn |> redirect(to: Routes.organization_path(conn, :show, organization_id)) end)
  end
end
