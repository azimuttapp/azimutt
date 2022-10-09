defmodule AzimuttWeb.OrganizationInvitationController do
  use AzimuttWeb, :controller
  alias Azimutt.Organizations
  alias Azimutt.Organizations.OrganizationInvitation
  alias Azimutt.Services.StripeSrv

  def show(conn, %{"id" => id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user
    organization_invitation = Organizations.get_organization_invitation(id)

    render(conn, "show.html",
      organization_invitation: organization_invitation,
      organization: organization_invitation.organization,
      active_plan: :free
    )
  end

  def accept(conn, %{"id" => id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user

    case Organizations.accept_organization_invitation(id, current_user, now) do
      {:ok, invitation} ->
        if invitation.organization.stripe_subscription_id do
          {:ok, organization} = Organizations.get_organization(invitation.organization_id, current_user)
          StripeSrv.update_quantity(organization.stripe_subscription_id, length(organization.members) + 1)
        end

        conn
        |> put_flash(:info, "Welcome! You are now part of #{invitation.organization.name} organization 👍️")
        |> redirect(to: Routes.organization_path(conn, :show, invitation.organization_id))

      {:error, _} ->
        conn
        |> put_flash(:error, "Oups, this invitation failed on acceptation 😵")
        |> redirect(to: Routes.user_dashboard_path(conn, :index))
    end
  end

  def refuse(conn, %{"id" => id}) do
    now = DateTime.utc_now()
    current_user = conn.assigns.current_user

    case Organizations.refuse_organization_invitation(id, current_user, now) do
      {:ok, invitation} ->
        conn
        |> put_flash(:info, "Ok, let's not join #{invitation.organization.name} organization 🤷")
        |> redirect(to: Routes.user_dashboard_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Oups, this invitation failed on rejection 😵")
        |> redirect(to: Routes.user_dashboard_path(conn, :index))
    end
  end
end
