defmodule AzimuttWeb.ElmController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  # every action is the same, just load the Elm index but we need different actions for the reverse router
  def create(conn, params), do: conn |> load_elm_with_org(:org_create, params)
  def new(conn, params), do: conn |> load_elm_with_org(:org_new, params)
  def org_create(conn, _params), do: conn |> load_elm
  def org_new(conn, _params), do: conn |> load_elm
  def embed(conn, _params), do: conn |> load_elm

  def org_show(conn, %{"organization_id" => organization_id}) do
    if organization_id |> String.length() == 36 do
      conn |> redirect(to: Routes.organization_path(conn, :show, organization_id))
    else
      {:error, :not_found}
    end
  end

  def project_show(conn, %{"organization_id" => _organization_id, "project_id" => project_id}) do
    current_user = conn.assigns.current_user

    if !current_user || current_user.confirmed_at || !Azimutt.config(:require_email_confirmation) do
      if project_id |> String.length() == 36 do
        conn |> load_elm
      else
        {:error, :not_found}
      end
    else
      conn |> redirect(to: Routes.user_confirmation_path(conn, :new))
    end
  end

  defp load_elm(conn) do
    conn |> render("index.html")
  end

  defp load_elm_with_org(conn, route, params) do
    current_user = conn.assigns.current_user

    if current_user do
      plans = Azimutt.plans() |> Map.values() |> Enum.map(fn p -> {Atom.to_string(p.id), p.order} end) |> Map.new()
      best_org = current_user.members |> Enum.map(fn m -> m.organization end) |> Enum.sort_by(fn o -> plans |> Map.get(o.plan, 0) end, :desc) |> hd()
      path = Routes.elm_path(conn, route, best_org.id) <> if map_size(params) == 0, do: "", else: "?" <> URI.encode_query(params, :rfc3986)
      conn |> redirect(to: path)
    else
      conn |> load_elm
    end
  end
end
