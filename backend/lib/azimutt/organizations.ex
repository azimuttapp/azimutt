defmodule Azimutt.Organizations do
  @moduledoc "The Organizations context."
  require Logger
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Accounts.UserNotifier
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationInvitation
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Organizations.OrganizationPlan
  alias Azimutt.Repo
  alias Azimutt.Services.StripeSrv
  alias Azimutt.Utils.Enumx
  alias Azimutt.Utils.Result

  def get_organization(id, %User{} = current_user) do
    Organization
    |> join(:inner, [o], om in OrganizationMember, on: om.organization_id == o.id)
    |> where([o, om], om.user_id == ^current_user.id and o.id == ^id)
    |> preload(members: [:user, :created_by, :updated_by])
    # TODO: can filter projects? (ignore local projects not owned by the current_user)
    |> preload(:projects)
    |> preload(:invitations)
    |> preload(:created_by)
    |> preload(:updated_by)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def list_organizations(%User{} = current_user) do
    Organization
    |> join(:inner, [o], om in OrganizationMember, on: om.organization_id == o.id)
    |> where([o, om], om.user_id == ^current_user.id)
    |> preload(:members)
    |> preload(:projects)
    |> preload(:invitations)
    |> Repo.all()
  end

  def create_personal_organization(%User{} = current_user) do
    StripeSrv.init_customer("TMP - #{current_user.name}")
    |> Result.flat_map(fn stripe_customer ->
      member_changeset = OrganizationMember.creator_changeset(current_user)

      %Organization{}
      |> Repo.preload(:members)
      |> Organization.create_personal_changeset(current_user, stripe_customer)
      |> Ecto.Changeset.put_assoc(:members, [member_changeset])
      |> Repo.insert()
      |> Result.tap_both(
        fn _err -> StripeSrv.delete_customer(stripe_customer) end,
        fn org -> stripe_update_customer(stripe_customer, org, current_user, true) end
      )
    end)
  end

  def create_non_personal_organization(attrs, %User{} = current_user) do
    StripeSrv.init_customer("TMP - #{attrs[:name]}")
    |> Result.flat_map(fn stripe_customer ->
      member_changeset = OrganizationMember.creator_changeset(current_user)

      %Organization{}
      |> Repo.preload(:members)
      |> Organization.create_non_personal_changeset(current_user, stripe_customer, attrs)
      |> Ecto.Changeset.put_assoc(:members, [member_changeset])
      |> Repo.insert()
      |> Result.tap_both(
        fn _err -> StripeSrv.delete_customer(stripe_customer) end,
        fn org -> stripe_update_customer(stripe_customer, org, current_user, false) end
      )
    end)
  end

  defp stripe_update_customer(%Stripe.Customer{} = stripe_customer, %Organization{} = organization, %User{} = current_user, is_personal) do
    StripeSrv.update_organization(
      stripe_customer,
      organization.id,
      organization.name,
      organization.contact_email,
      organization.description,
      is_personal,
      current_user.name,
      current_user.email
    )
  end

  def update_organization(attrs, %Organization{} = organization, %User{} = current_user) do
    organization
    |> Organization.update_changeset(attrs, current_user)
    |> Repo.update()
  end

  def update_organization_subscription(customer_id, subscription_id) do
    organization = Azimutt.Repo.get_by!(Organization, stripe_customer_id: customer_id)

    if organization.stripe_subscription_id do
      Logger.error("Organization #{organization.id} as already a subscription #{organization.stripe_subscription_id}, it will be replace")
    end

    organization = Ecto.Changeset.change(organization, stripe_subscription_id: subscription_id)
    Azimutt.Repo.update!(organization)
  end

  # Organization members

  def has_member?(%Organization{} = organization, %User{} = current_user) do
    organization.members |> Enum.any?(fn m -> m.user.id == current_user.id end)
  end

  def remove_member(%Organization{} = organization, member_id) do
    with {:ok, %OrganizationMember{} = member} <- organization.members |> Enum.filter(fn m -> m.user.id == member_id end) |> Enumx.one(),
         {:ok, _} <- Repo.delete(member),
         do: {:ok, member}
  end

  # Organization invitations

  def get_organization_invitation(id) do
    OrganizationInvitation
    |> where([oi], oi.id == ^id)
    |> preload(:organization)
    |> preload(:created_by)
    |> preload(:answered_by)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def get_user_organization_invitation(%User{} = user, %Organization{} = organization, now) do
    OrganizationInvitation
    |> where(
      [oi],
      oi.sent_to == ^user.email and oi.organization_id == ^organization.id and oi.expire_at > ^now and is_nil(oi.cancel_at) and
        is_nil(oi.accepted_at) and is_nil(oi.refused_at)
    )
    |> preload(:organization)
    |> Repo.one()
  end

  def create_organization_invitation(attrs, invitation_url, organization_id, current_user, now) do
    %OrganizationInvitation{}
    |> OrganizationInvitation.create_changeset(attrs, organization_id, current_user, Timex.shift(now, days: 7))
    |> Repo.insert()
    |> case do
      {:ok, organization_invitation} ->
        with {:ok, i} <- get_organization_invitation(organization_invitation.id),
             do: UserNotifier.deliver_organization_invitation_instructions(i, i.organization, i.created_by, invitation_url.(i.id))

        {:ok, organization_invitation}

      error ->
        error
    end
  end

  def accept_organization_invitation(id, %User{} = current_user, now) do
    {:ok, invitation} = get_organization_invitation(id)

    if is_valid(invitation, current_user, now) do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:add_member, OrganizationMember.new_member_changeset(invitation.organization_id, current_user))
      |> Ecto.Multi.update(:accept_invitation, OrganizationInvitation.accept_changeset(invitation, current_user, now))
      |> Repo.transaction()
      |> case do
        {:ok, _} ->
          {:ok, invitation}

        {:error, :add_member, changeset, _} ->
          {:error, changeset}

        {:error, :accept_invitation, changeset, _} ->
          {:error, changeset}
      end
    else
      {:error, :invalid}
    end
  end

  def refuse_organization_invitation(id, %User{} = current_user, now) do
    {:ok, invitation} = get_organization_invitation(id)

    if is_valid(invitation, current_user, now) do
      Ecto.Multi.new()
      |> Ecto.Multi.update(:refuse_invitation, OrganizationInvitation.refuse_changeset(invitation, current_user, now))
      |> Repo.transaction()
      |> case do
        {:ok, _} ->
          {:ok, invitation}

        {:error, :refuse_invitation, changeset, _} ->
          {:error, changeset}
      end
    else
      {:error, :invalid}
    end
  end

  defp is_valid(%OrganizationInvitation{} = invitation, %User{} = current_user, now) do
    invitation.sent_to == current_user.email && invitation.cancel_at == nil && invitation.accepted_at == nil && invitation.refused_at == nil &&
      invitation.expire_at > now
  end

  def cancel_organization_invitation(id, %User{} = current_user, now) do
    {:ok, invitation} = get_organization_invitation(id)

    if invitation.created_by_id == current_user.id do
      Ecto.Multi.new()
      |> Ecto.Multi.update(:cancel_invitation, OrganizationInvitation.cancel_changeset(invitation, current_user, now))
      |> Repo.transaction()
      |> case do
        {:ok, _} ->
          {:ok, invitation}

        {:error, :cancel_invitation, changeset, _} ->
          {:error, changeset}
      end
    else
      {:error, :not_owner}
    end
  end

  def delete_organization(%Organization{} = organization) do
    # FIXME: check current_user is owner
    Repo.delete(organization)
  end

  def get_subscription_status(stripe_subscription_id) when is_bitstring(stripe_subscription_id) do
    with {:ok, subscription} <- StripeSrv.get_subscription(stripe_subscription_id) do
      case subscription.status do
        "active" ->
          :active

        "past_due" ->
          :past_due

        "unpaid" ->
          :unpaid

        "canceled" ->
          :canceled

        "incomplete" ->
          :incomplete

        "incomplete_expired" ->
          :incomplete_expired

        "trialing" ->
          :trialing

        other ->
          Logger.warning("Get unexpected subscription status : #{other}")
          :incomplete
      end
    end
  end

  def get_organization_plan(%Organization{} = organization) do
    if organization.stripe_subscription_id do
      StripeSrv.get_subscription(organization.stripe_subscription_id)
      |> Result.map(fn s ->
        if s.status == "active" || s.status == "past_due" || s.status == "unpaid" do
          OrganizationPlan.team()
        else
          OrganizationPlan.free()
        end
      end)
    else
      {:ok, OrganizationPlan.free()}
    end
  end
end
