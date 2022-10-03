defmodule AzimuttWeb.OrganizationInvitationController do
  use AzimuttWeb, :controller
  alias Azimutt.Organizations
  alias Azimutt.Organizations.OrganizationInvitation

  def show(conn, %{"id" => id}) do
    organization_invitation = Organizations.get_organization_invitation(id)

    render(conn, "show.html",
      organization_invitation: organization_invitation,
      organization: organization_invitation.organization
    )
  end

  def accept(conn, %{"id" => id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user
    organization_invitation = Organizations.get_organization_invitation(id)

    case Organizations.accept_organization_invitation(organization_invitation, current_user, now) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Organization invitation accepted.")
        |> redirect(to: Routes.organization_path(conn, :show, organization_invitation.organization_id))

      {:error, _} ->
        conn
        |> put_flash(:error, "Organization invitation could not be accepted.")
        |> redirect(to: Routes.user_dashboard_path(conn, :index))
    end
  end

  def refuse(conn, %{"id" => id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user
    organization_invitation = Organizations.get_organization_invitation(id)

    case Organizations.refuse_organization_invitation(organization_invitation, current_user, now) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Organization invitation refused")
        |> redirect(to: Routes.user_dashboard_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Organization invitation could not be refused.")
        |> redirect(to: Routes.user_dashboard_path(conn, :index))
    end
  end

  def cancel(conn, %{"id" => id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user
    organization_invitation = Organizations.get_organization_invitation(id)

    case Organizations.cancel_organization_invitation(organization_invitation, current_user, now) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Organization invitation cancel")
        |> redirect(to: Routes.organization_member_path(conn, :index, organization_invitation.organization_id))

      {:error, _} ->
        conn
        |> put_flash(:error, "Organization invitation could not be refused.")
        |> redirect(to: Routes.organization_member_path(conn, :index, organization_invitation.organization_id))
    end
  end
end
