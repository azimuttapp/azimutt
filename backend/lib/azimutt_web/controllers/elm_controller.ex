defmodule AzimuttWeb.ElmController do
  use AzimuttWeb, :controller
  action_fallback AzimuttWeb.FallbackController

  # every action is the same, just load the Elm index but we need different actions for the reverse router
  def create(conn, _params), do: conn |> load_elm
  def embed(conn, _params), do: conn |> load_elm
  def new(conn, _params), do: conn |> load_elm
  def orga_create(conn, _params), do: conn |> load_elm
  def orga_new(conn, _params), do: conn |> load_elm

  def orga_show(conn, %{"organization_id" => organization_id}) do
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
end
