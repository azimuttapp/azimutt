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
        conn |> redirect(to: Routes.organization_path(conn, :show, p.organization_id))

      # conn |> redirect(to: Routes.elm_path(conn, :project_show, p.organization_id, p.id))

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

  def aml(conn, _params), do: conn |> render("aml.html")
  def converters(conn, _params), do: conn |> render("converters/index.html")

  def converter(conn, %{"from" => from}) do
    Azimutt.converters()
    |> Enum.find(fn c -> c.id == from end)
    |> Result.from_nillable()
    |> Result.map(fn converter -> conn |> render("converters/converter.html", converter: converter) end)
  end

  def convert(conn, %{"from" => from_id, "to" => to_id}) do
    from_converter = Azimutt.converters() |> Enum.find(fn c -> c.id == from_id end) |> Result.from_nillable()
    to_converter = Azimutt.converters() |> Enum.find(fn c -> c.id == to_id end) |> Result.from_nillable()

    from_converter
    |> Result.flat_map(fn f -> to_converter |> Result.map(fn t -> {f, t} end) end)
    |> Result.map(fn {from, to} -> conn |> render("converters/convert.html", from: from, to: to) end)
  end

  def portal(conn, _params), do: conn |> render("portal.html")
  def portal_subscribed(conn, _params), do: conn |> render("portal-subscribed.html")

  def docs(conn, _params),
    do: conn |> render("docs/index.html", page: %{slug: "index", name: "Azimutt Documentation", children: Azimutt.doc_pages(), parents: []}, prev: nil, next: nil)

  def doc(conn, %{"slug" => slug}) do
    pages = Azimutt.doc_pages_flat()

    pages
    |> Enum.find_index(fn p -> p.slug == slug end)
    |> Result.from_nillable()
    |> Result.map(fn index ->
      conn |> render("docs/#{slug}.html", page: pages |> Enum.at(index), prev: if(index > 0, do: pages |> Enum.at(index - 1), else: nil), next: pages |> Enum.at(index + 1))
    end)
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

  def use_cases_index(conn, _params), do: conn |> render("use-cases/index.html")

  def use_cases_show(conn, %{"use_case_id" => use_case_id}) do
    Azimutt.showcase_usages()
    |> Enum.find(fn u -> u.id == use_case_id end)
    |> Result.from_nillable()
    |> Result.map(fn use_case -> conn |> render("use-cases/#{use_case_id}.html", use_case: use_case) end)
  end

  def features_index(conn, _params), do: conn |> render("features/index.html")

  def features_show(conn, %{"feature_id" => feature_id}) do
    Azimutt.showcase_features()
    |> Enum.find_index(fn f -> f.id == feature_id end)
    |> Result.from_nillable()
    |> Result.map(fn index ->
      conn
      |> render("features/#{feature_id}.html",
        feature: Azimutt.showcase_features() |> Enum.at(index),
        previous: if(index > 0, do: Azimutt.showcase_features() |> Enum.at(index - 1), else: nil),
        next: Azimutt.showcase_features() |> Enum.at(index + 1)
      )
    end)
  end

  def pricing(conn, _params), do: conn |> render("pricing.html", dark: true)

  def terms(conn, _params), do: conn |> render("terms.html")

  def privacy(conn, _params), do: conn |> render("privacy.html")

  def resources(conn, _params), do: conn |> render("resources.html")
end
