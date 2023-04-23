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
      {:ok, p} ->
        # conn |> redirect(to: Routes.organization_path(conn, :show, p.organization_id))
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
    conn |> get_req_header("referer") |> Enum.any?(fn h -> h |> String.contains?(Azimutt.config(:host)) end)
  end

  def use_cases_index(conn, _params), do: conn |> render("use-cases.html")

  def use_cases_show(conn, %{"id" => id}) do
    Azimutt.use_cases()
    |> Enum.find(fn u -> u.id == id end)
    |> Result.from_nillable()
    |> Result.map(fn use_case -> conn |> render("use-case-#{id}.html", use_case: use_case) end)
  end

  def features_index(conn, _params), do: conn |> render("features.html")

  def features_show(conn, %{"id" => id}) do
    Azimutt.features()
    |> Enum.find_index(fn f -> f.id == id end)
    |> Result.from_nillable()
    |> Result.map(fn index ->
      conn
      |> render("feature-#{id}.html",
        feature: Azimutt.features() |> Enum.at(index),
        previous: if(index > 0, do: Azimutt.features() |> Enum.at(index - 1), else: nil),
        next: Azimutt.features() |> Enum.at(index + 1)
      )
    end)
  end

  def pricing(conn, _params), do: conn |> render("pricing.html", dark: true)

  def terms(conn, _params), do: conn |> render("terms.html")
end
