defmodule Azimutt.Organizations do
  @moduledoc "The Organizations context."
  require Logger
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Accounts.UserNotifier
  alias Azimutt.Heroku
  alias Azimutt.Heroku.Resource
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationInvitation
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Organizations.OrganizationPlan
  alias Azimutt.Projects.Project
  alias Azimutt.Repo
  alias Azimutt.Services.StripeSrv
  alias Azimutt.Utils.Enumx
  alias Azimutt.Utils.Result

  def get_organization(id, %User{} = current_user) do
    Organization
    |> join(:inner, [o], om in OrganizationMember, on: om.organization_id == o.id)
    |> where([o, om], om.user_id == ^current_user.id and o.id == ^id and is_nil(o.deleted_at))
    |> preload(members: [:user, :created_by, :updated_by])
    # TODO: can filter projects? (ignore local projects not owned by the current_user)
    |> preload(:projects)
    |> preload(:heroku_resource)
    |> preload(:invitations)
    |> preload(:created_by)
    |> preload(:updated_by)
    |> Repo.one()
    |> Result.from_nillable()
  end

  # /!\ should be only used in stripe_handler.ex
  def get_organization_by_customer(customer_id) do
    # Repo.get_by(Organization, stripe_customer_id: customer_id)
    # |> preload([:created_by])
    Organization
    |> where([o], o.stripe_customer_id == ^customer_id)
    |> preload(:created_by)
    |> Repo.one()
    |> Result.from_nillable()
  end

  def list_organizations(%User{} = current_user) do
    Organization
    |> join(:inner, [o], om in OrganizationMember, on: om.organization_id == o.id)
    |> where([o, om], om.user_id == ^current_user.id and is_nil(o.deleted_at))
    |> preload(:members)
    |> preload(:projects)
    |> preload(:heroku_resource)
    |> preload(:invitations)
    |> Repo.all()
  end

  def create_personal_organization(%User{} = current_user) do
    %Organization{}
    |> Repo.preload(:members)
    |> Organization.create_personal_changeset(current_user)
    |> Ecto.Changeset.put_assoc(:members, [OrganizationMember.creator_changeset(current_user)])
    |> Repo.insert()
    |> Result.flat_map(fn orga ->
      if StripeSrv.stripe_configured?() do
        create_stripe_customer(orga, current_user)
      else
        {:ok, orga}
      end
    end)
  end

  def create_non_personal_organization(attrs, %User{} = current_user) do
    %Organization{}
    |> Repo.preload(:members)
    |> Organization.create_non_personal_changeset(current_user, attrs)
    |> Ecto.Changeset.put_assoc(:members, [OrganizationMember.creator_changeset(current_user)])
    |> Repo.insert()
    |> Result.flat_map(fn orga ->
      if StripeSrv.stripe_configured?() do
        create_stripe_customer(orga, current_user)
      else
        {:ok, orga}
      end
    end)
  end

  def create_stripe_customer(%Organization{} = organization, %User{} = current_user) do
    if organization.stripe_customer_id == nil do
      StripeSrv.create_customer(
        organization.id,
        organization.name,
        current_user.email,
        organization.description,
        organization.is_personal,
        current_user.name,
        current_user.email
      )
      |> Result.flat_map(fn customer ->
        organization
        |> Organization.add_stripe_customer_changeset(customer)
        |> Repo.update()
      end)
    else
      {:error, "Stripe customer already set for organization #{organization.name} (#{organization.id})"}
    end
  end

  def update_organization(attrs, %Organization{} = organization, %User{} = current_user) do
    organization
    |> Organization.update_changeset(attrs, current_user)
    |> Repo.update()
  end

  def update_organization_subscription(%Organization{} = organization, subscription_id) do
    if organization.stripe_subscription_id do
      Logger.error("Organization #{organization.id} as already a subscription #{organization.stripe_subscription_id}, it will be replace")
    end

    organization = Ecto.Changeset.change(organization, stripe_subscription_id: subscription_id)
    Repo.update!(organization)
  end

  # Organization members

  def has_member?(%Organization{} = organization, %User{} = current_user) do
    OrganizationMember
    |> where([om], om.organization_id == ^organization.id and om.user_id == ^current_user.id)
    |> Repo.exists?()
  end

  def count_member(%Organization{} = organization) do
    OrganizationMember
    |> where([om], om.organization_id == ^organization.id)
    |> Repo.aggregate(:count, :user_id)
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
    |> preload(organization: :heroku_resource)
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
    |> preload(organization: :heroku_resource)
    |> Repo.one()
  end

  def create_organization_invitation(attrs, url_fun, organization_id, current_user, now) when is_function(url_fun, 1) do
    %OrganizationInvitation{}
    |> OrganizationInvitation.create_changeset(attrs, organization_id, current_user, Timex.shift(now, days: 7))
    |> Repo.insert()
    |> case do
      {:ok, organization_invitation} ->
        with {:ok, i} <- get_organization_invitation(organization_invitation.id),
             do: UserNotifier.send_organization_invitation(i, i.organization, i.created_by, url_fun.(i.id))

        {:ok, organization_invitation}

      error ->
        error
    end
  end

  def accept_organization_invitation(id, %User{} = current_user, now) do
    {:ok, invitation} = get_organization_invitation(id)

    error = has_error(invitation, current_user, now)

    if error === false do
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
      {:error, error}
    end
  end

  def refuse_organization_invitation(id, %User{} = current_user, now) do
    {:ok, invitation} = get_organization_invitation(id)
    error = has_error(invitation, current_user, now)

    if error === false do
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
      {:error, error}
    end
  end

  defp has_error(%OrganizationInvitation{} = invitation, %User{} = current_user, now) do
    cond do
      invitation.sent_to != current_user.email -> "email_not_matching"
      invitation.cancel_at != nil -> "already_canceled"
      invitation.accepted_at != nil -> "already_accepted"
      invitation.refused_at != nil -> "already_refused"
      Date.compare(invitation.expire_at, now) == :lt -> "already_expired"
      true -> false
    end
  end

  def cancel_organization_invitation(id, %User{} = current_user, now) do
    {:ok, invitation} = get_organization_invitation(id)

    # only orga members can cancel orga invitations
    if current_user.organizations |> Enum.find(fn o -> o.id == invitation.organization_id end) do
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
      {:error, :not_allowed}
    end
  end

  def delete_organization(%Organization{} = organization, now) do
    # TODO decide between soft and hard delete of organization, if hard, add tracking events
    Project
    |> where([p], p.organization_id == ^organization.id)
    |> Repo.delete_all()

    organization
    |> Organization.delete_changeset(now)
    |> Repo.update()
  end

  def get_subscription_status(stripe_subscription_id) when is_bitstring(stripe_subscription_id) do
    with {:ok, subscription} <- StripeSrv.get_subscription(stripe_subscription_id) do
      case subscription.status do
        "active" ->
          {:ok, :active}

        "past_due" ->
          {:ok, :past_due}

        "unpaid" ->
          {:ok, :unpaid}

        "canceled" ->
          {:ok, :canceled}

        "incomplete" ->
          {:ok, :incomplete}

        "incomplete_expired" ->
          {:ok, :incomplete_expired}

        "trialing" ->
          {:ok, :trialing}

        other ->
          Logger.warning("Get unexpected subscription status : #{other}")
          {:ok, :incomplete}
      end
    end
  end

  def get_allowed_members(%Organization{} = organization, %OrganizationPlan{} = plan) do
    cond do
      organization.heroku_resource ->
        Heroku.allowed_members(organization.heroku_resource.plan)

      plan.id == :pro ->
        # means no limit
        nil

      true ->
        Azimutt.config(:free_plan_seats)
    end
  end

  def allow_table_color(%Organization{} = organization, tweet_url) when is_binary(tweet_url) do
    organization
    |> Organization.allow_table_color_changeset(tweet_url)
    |> Repo.update()
  end

  def get_organization_plan(%Organization{} = organization) do
    cond do
      organization.heroku_resource -> heroku_plan(organization.heroku_resource)
      organization.stripe_subscription_id && StripeSrv.stripe_configured?() -> stripe_plan(organization.stripe_subscription_id)
      true -> default_plan()
    end
    |> Result.map(fn plan -> plan_overrides(organization, plan) end)
  end

  defp heroku_plan(%Resource{} = resource) do
    if resource.plan |> String.starts_with?("pro-") do
      {:ok, OrganizationPlan.pro()}
    else
      {:ok, OrganizationPlan.free()}
    end
  end

  defp stripe_plan(subscription_id) do
    StripeSrv.get_subscription(subscription_id)
    |> Result.map(fn s ->
      if s.status == "active" || s.status == "past_due" || s.status == "unpaid" do
        OrganizationPlan.pro()
      else
        OrganizationPlan.free()
      end
    end)
  end

  def default_plan do
    case Azimutt.config(:organization_default_plan) do
      "pro" -> {:ok, OrganizationPlan.pro()}
      _ -> {:ok, OrganizationPlan.free()}
    end
  end

  defp plan_overrides(%Organization{} = organization, %OrganizationPlan{} = plan) do
    if organization.data != nil do
      plan
      |> override_layouts(organization.data)
      |> override_memos(organization.data)
      |> override_colors(organization.data)
      |> override_private_links(organization.data)
      |> override_analysis(organization.data)
    else
      plan
    end
  end

  defp override_layouts(%OrganizationPlan{} = plan, %Organization.Data{} = data) do
    if data.allowed_layouts != nil do
      %{plan | layouts: best_limit(plan.layouts, data.allowed_layouts)}
    else
      plan
    end
  end

  defp override_memos(%OrganizationPlan{} = plan, %Organization.Data{} = data) do
    if data.allowed_memos != nil do
      %{plan | memos: best_limit(plan.memos, data.allowed_memos)}
    else
      plan
    end
  end

  defp override_colors(%OrganizationPlan{} = plan, %Organization.Data{} = data) do
    if data.allow_table_color do
      %{plan | colors: true}
    else
      plan
    end
  end

  defp override_private_links(%OrganizationPlan{} = plan, %Organization.Data{} = data) do
    if data.allow_private_links do
      %{plan | private_links: true}
    else
      plan
    end
  end

  defp override_analysis(%OrganizationPlan{} = plan, %Organization.Data{} = data) do
    if data.allow_database_analysis do
      %{plan | db_analysis: true}
    else
      plan
    end
  end

  defp best_limit(a, b) do
    cond do
      a == nil || b == nil -> nil
      is_integer(a) && is_integer(b) -> max(a, b)
      is_integer(a) -> a
      is_integer(b) -> b
    end
  end
end
