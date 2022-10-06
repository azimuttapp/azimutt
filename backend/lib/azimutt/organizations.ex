defmodule Azimutt.Organizations do
  @moduledoc "The Organizations context."
  require Logger
  import Ecto.Query, warn: false
  alias Azimutt.Accounts.User
  alias Azimutt.Accounts.UserNotifier
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.Organization.Benefits
  alias Azimutt.Organizations.OrganizationInvitation
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Repo
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

  def has_member?(%Organization{} = organization, %User{} = current_user) do
    organization.members |> Enum.any?(fn m -> m.user.id == current_user.id end)
  end

  def create_personal_organization(%User{} = current_user) do
    member_changeset = OrganizationMember.creator_changeset(current_user)

    %Organization{}
    |> Repo.preload(:members)
    |> Organization.create_personal_changeset(current_user)
    |> Ecto.Changeset.put_assoc(:members, [member_changeset])
    |> Repo.insert()
  end

  def create_non_personal_organization(attrs \\ %{}, %User{} = current_user) do
    member_changeset = OrganizationMember.creator_changeset(current_user)

    %Organization{}
    |> Repo.preload(:members)
    |> Organization.create_non_personal_changeset(attrs, current_user)
    |> Ecto.Changeset.put_assoc(:members, [member_changeset])
    |> Repo.insert()
  end

  def accept_organization_invitation(%OrganizationInvitation{} = organization_invitation, %User{} = current_user, now) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:add_member, OrganizationMember.new_member_changeset(organization_invitation.organization_id, current_user))
      |> Ecto.Multi.update(:accept_invitation, OrganizationInvitation.accept_changeset(organization_invitation, current_user, now))
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        {:ok, nil}

      {:error, :add_member, changeset, _} ->
        {:error, changeset}

      {:error, :accept_invitation, changeset, _} ->
        {:error, changeset}
    end
  end

  def refuse_organization_invitation(%OrganizationInvitation{} = organization_invitation, %User{} = current_user, now) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:refuse_invitation, OrganizationInvitation.refuse_changeset(organization_invitation, current_user, now))
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        {:ok, nil}

      {:error, :refuse_invitation, changeset, _} ->
        {:error, changeset}
    end
  end

  def cancel_organization_invitation(%OrganizationInvitation{} = organization_invitation, %User{} = current_user, now) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:cancel_invitation, OrganizationInvitation.cancel_changeset(organization_invitation, current_user, now))
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        {:ok, nil}

      {:error, :cancel_invitation, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_organization(%Organization{} = organization, attrs, %User{} = current_user) do
    organization
    |> Organization.update_changeset(attrs, current_user)
    |> Repo.update()
  end

  def delete_organization(%Organization{} = organization) do
    Repo.delete(organization)
  end

  def list_organization_invitations do
    Repo.all(OrganizationInvitation)
  end

  def list_organization_invitations(id) do
    Repo.all(OrganizationInvitation, id)
  end

  def get_organization_invitation(id) do
    OrganizationInvitation
    |> where([oi], oi.id == ^id)
    |> preload(:organization)
    |> preload(:answered_by)
    |> Repo.one()
  end

  def get_user_organization_invitation(%User{} = user, %Organization{} = organization) do
    OrganizationInvitation
    |> where([oi], oi.sent_to == ^user.email and oi.organization_id == ^organization.id)
    |> preload(:organization)
    |> Repo.one()
  end

  def create_organization_invitation(attrs \\ %{}, invitation_url, organization_id, current_user, now) do
    %OrganizationInvitation{}
    |> OrganizationInvitation.create_changeset(attrs, organization_id, current_user, Timex.shift(now, days: 7))
    |> Repo.insert()
    |> case do
      {:ok, organization_invitation} ->
        UserNotifier.deliver_organization_invitation_instructions(organization_invitation, invitation_url.(organization_invitation.id))
        {:ok, organization_invitation}

      error ->
        error
    end
  end

  def get_organization_benefits(%Organization{} = organization) do
    if organization.active_plan == :team do
      {:ok,
       %Benefits{
         members: 5,
         layouts: nil,
         colors: true,
         db_analysis: true,
         db_access: true
       }}
    else
      {:ok,
       %Benefits{
         members: 3,
         layouts: 3,
         colors: false,
         db_analysis: false,
         db_access: false
       }}
    end
  end
end
