defmodule AzimuttWeb.WebsiteController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts.User
  alias Azimutt.Projects
  alias Azimutt.Tracking
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    last_project =
      with {:ok, %User{} = current_user} <- conn.assigns.current_user |> Result.from_nillable(),
           {:ok, %Event{} = event} <- Tracking.last_project_loaded(current_user),
           do: Projects.get_project(event.project_id, current_user)

    case last_project |> Result.filter_not(fn _p -> same_domain?(conn) end) do
      # {:ok, p} -> conn |> redirect(to: Routes.organization_path(conn, :show, p.organization_id))
      {:ok, p} -> conn |> redirect(to: Routes.elm_path(conn, :project_show, p.organization_id, p.id))
      _ -> conn |> render("index.html")
    end
  end

  defp same_domain?(conn) do
    get_req_header(conn, "referer") |> Enum.any?(fn h -> h |> String.contains?(Azimutt.config(:domain)) end)
  end
end
