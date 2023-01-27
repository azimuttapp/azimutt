defmodule AzimuttWeb.WebsiteController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts.User
  alias Azimutt.Projects
  alias Azimutt.Tracking
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    case conn |> last_used_project |> Result.filter_not(fn _p -> same_domain?(conn) end) do
      # {:ok, p} -> conn |> redirect(to: Routes.organization_path(conn, :show, p.organization_id))
      {:ok, p} ->
        conn |> redirect(to: Routes.elm_path(conn, :project_show, p.organization_id, p.id))

      _ ->
        if Azimutt.config(:skip_public_site) do
          conn.assigns.current_user
          |> Result.from_nillable()
          |> Result.map(fn _user -> conn |> redirect(to: Routes.user_dashboard_path(conn, :index)) end)
          |> Result.or_else(conn |> redirect(to: Routes.user_session_path(conn, :new)))
        else
          conn |> render("index.html")
        end
    end
  end

  def last(conn, _params) do
    case conn |> last_used_project do
      {:ok, p} -> conn |> redirect(to: Routes.elm_path(conn, :project_show, p.organization_id, p.id))
      _ -> conn |> redirect(to: Routes.user_dashboard_path(conn, :index))
    end
  end

  defp last_used_project(conn) do
    with {:ok, %User{} = current_user} <- conn.assigns.current_user |> Result.from_nillable(),
         {:ok, %Event{} = event} <- Tracking.last_used_project(current_user),
         do: Projects.get_project(event.project_id, current_user)
  end

  defp same_domain?(conn) do
    get_req_header(conn, "referer") |> Enum.any?(fn h -> h |> String.contains?(Azimutt.config(:domain)) end)
  end

  def analyze(conn, _params), do: conn |> render("use-case-analyze.html")
  def design(conn, _params), do: conn |> render("use-case-design.html")
  def document(conn, _params), do: conn |> render("use-case-document.html")
  def explore(conn, _params), do: conn |> render("use-case-explore.html")
end
