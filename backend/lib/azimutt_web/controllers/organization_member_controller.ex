defmodule AzimuttWeb.OrganizationMemberController do
  use AzimuttWeb, :controller
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationInvitation

  def index(conn, %{"organization_id" => organization_id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user),
         {:ok, organization_benefits} <- Organizations.get_organization_benefits(organization) do
      organization_invitation_changeset =
        OrganizationInvitation.create_changeset(%OrganizationInvitation{}, %{}, organization.id, current_user, now)

      # FIXME: create a `Organizations.get_pending_invitations(organization.id)`
      organization_invitations =
        organization.invitations
        |> Enum.filter(fn invitation -> invitation.accepted_at == nil and invitation.cancel_at == nil and invitation.refused_at == nil end)

      render(conn, "index.html",
        organization: organization,
        organization_benefits: organization_benefits,
        organization_invitations: organization_invitations,
        organization_invitation_changeset: organization_invitation_changeset
      )
    end
  end

  def invite(conn, %{
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
        |> redirect(to: Routes.organization_member_path(conn, :index, organization_invitation.organization_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        organization_invitations = Organizations.list_organization_invitations()

        render(conn, "index.html",
          organization: organization,
          organization_invitations: organization_invitations,
          organization_invitation_changeset: changeset
        )
    end
  end
end
