defmodule AzimuttWeb.Utils.ControllerHelpers do
  @moduledoc "Common code for controllers."
  use AzimuttWeb, :controller
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization

  def for_owners(conn, %Organization{} = organization, %User{} = current_user, exec) do
    if Organizations.owner?(organization, current_user) do
      exec.()
    else
      conn
      |> put_flash(:warn, "You need owner rights.")
      |> redirect(to: Routes.organization_path(conn, :show, organization.id))
    end
  end
end
