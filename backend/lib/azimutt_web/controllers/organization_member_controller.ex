defmodule AzimuttWeb.OrganizationMemberController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationInvitation
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Utils.Uuid
  action_fallback AzimuttWeb.FallbackController

  def index(conn, %{"organization_organization_id" => organization_id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user

    if organization_id == Uuid.zero() do
      organization = Accounts.get_user_default_organization(current_user)
      conn |> redirect(to: Routes.organization_member_path(conn, :index, organization))
    end

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user) do
      organization_invitation_changeset = OrganizationInvitation.create_changeset(%OrganizationInvitation{}, %{}, organization.id, current_user, now)
      render_index(conn, organization, current_user, organization_invitation_changeset)
    end
  end

  def create_invitation(conn, %{
        "organization_organization_id" => organization_id,
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
      {:ok, invitation} ->
        conn
        |> put_flash(:info, "Invited #{invitation.sent_to} to #{organization.name} 🚀")
        |> redirect(to: Routes.organization_member_path(conn, :index, invitation.organization_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render_index(conn, organization, current_user, changeset)
    end
  end

  def cancel_invitation(conn, %{"organization_organization_id" => organization_id, "invitation_id" => invitation_id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user

    case Organizations.cancel_organization_invitation(invitation_id, current_user, now) do
      {:ok, invitation} ->
        conn
        |> put_flash(:info, "Canceled #{invitation.sent_to} invitation to #{invitation.organization.name}")
        |> redirect(to: Routes.organization_member_path(conn, :index, invitation.organization_id))

      {:error, err} ->
        message = if err == :not_allowed, do: "You don't have the rights to cancel this invitation.", else: "Failed to cancel invitation 😵"

        conn
        |> put_flash(:error, message)
        |> redirect(to: Routes.organization_member_path(conn, :index, organization_id))
    end
  end

  def remove(conn, %{"organization_organization_id" => organization_id, "user_id" => user_id}) do
    current_user = conn.assigns.current_user

    with {:ok, %Organization{} = organization} <- Organizations.get_organization(organization_id, current_user),
         {:ok, %OrganizationMember{} = member} <- Organizations.remove_member(organization, user_id) do
      # TODO: send email to removed user
      if member.user.id == current_user.id do
        conn
        |> put_flash(:info, "Successfully leaved #{organization.name}.")
        |> redirect(to: Routes.user_dashboard_path(conn, :index))
      else
        conn
        |> put_flash(:info, "Successfully removed #{member.user.name} from #{organization.name}.")
        |> redirect(to: Routes.organization_member_path(conn, :index, organization))
      end
    end
  end

  defp render_index(conn, organization, %User{} = current_user, changeset) do
    with {:ok, plan} <- Organizations.get_organization_plan(organization, current_user) do
      # TODO: create a `Organizations.get_pending_invitations(organization.id)`
      organization_invitations =
        organization.invitations
        |> Enum.filter(fn invitation -> invitation.accepted_at == nil and invitation.cancel_at == nil and invitation.refused_at == nil end)

      render(conn, "index.html",
        organization: organization,
        plan: plan,
        organization_invitations: organization_invitations,
        organization_invitation_changeset: changeset
      )
    end
  end
end
