defmodule AzimuttWeb.OrganizationInvitationController do
  use AzimuttWeb, :controller
  alias Azimutt.Organizations
  alias Azimutt.Organizations.OrganizationInvitation

  def index(conn, %{"organization_id" => organization_id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user
    {:ok, organization} = Organizations.get_organization(organization_id, current_user)

    organization_invitation_changeset =
      OrganizationInvitation.create_changeset(%OrganizationInvitation{}, %{}, organization.id, current_user, now)

    organization_invitations =
      organization.invitations
      |> Enum.filter(fn invitation -> invitation.accepted_at == nil and invitation.cancel_at == nil and invitation.refused_at == nil end)

    render(conn, "index.html",
      organization: organization,
      organization_invitations: organization_invitations,
      organization_invitation_changeset: organization_invitation_changeset
    )
  end

  def create(conn, %{
        "organization_id" => organization_id,
        "organization_invitation" => organization_invitation_params
      }) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user
    {:ok, organization} = Organizations.get_organization(organization_id, current_user)

    case Organizations.create_organization_invitation(
           organization_invitation_params,
           fn invitation_id -> Routes.invitation_url(conn, :show, invitation_id) end,
           organization.id,
           current_user,
           now
         ) do
      {:ok, organization_invitation} ->
        conn
        |> put_flash(:info, "Organization invitation send successfully.")
        |> redirect(to: Routes.organization_invitation_path(conn, :index, organization_invitation.organization_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        organization_invitations = Organizations.list_organization_invitations()

        render(conn, "index.html",
          organization: organization,
          organization_invitations: organization_invitations,
          organization_invitation_changeset: changeset
        )
    end
  end

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
        |> redirect(to: Routes.organization_invitation_path(conn, :index, organization_invitation.organization_id))

      {:error, _} ->
        conn
        |> put_flash(:error, "Organization invitation could not be refused.")
        |> redirect(to: Routes.organization_invitation_path(conn, :index, organization_invitation.organization_id))
    end
  end
end
