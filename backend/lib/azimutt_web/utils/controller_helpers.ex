defmodule AzimuttWeb.Utils.ControllerHelpers do
  @moduledoc "Common code for controllers."
  use AzimuttWeb, :controller
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationPlan

  def for_owners(conn, %Organization{} = organization, %User{} = current_user, exec) do
    if Organizations.owner?(organization, current_user) do
      exec.()
    else
      response_html(conn, organization, "You need Owner rights.")
    end
  end

  def for_writers_api(conn, %Organization{} = organization, %User{} = current_user, exec) do
    if Organizations.writer?(organization, current_user) do
      exec.()
    else
      response_json(conn, organization, "You need Writer rights.")
    end
  end

  def with_feature(conn, %Organization{} = organization, %OrganizationPlan{} = plan, feature, exec) do
    value = feature[plan.id]

    if is_boolean(value) && value do
      exec.()
    else
      response_html(conn, organization, "#{feature.name} not supported in #{plan.name} plan.")
    end
  end

  defp response_html(conn, %Organization{} = organization, message),
    do: conn |> put_flash(:warn, message) |> redirect(to: Routes.organization_path(conn, :show, organization.id))

  defp response_json(conn, %Organization{} = organization, message),
    do: conn |> put_status(:unauthorized) |> put_view(AzimuttWeb.ErrorView) |> render("error.json", %{message: message})
end
