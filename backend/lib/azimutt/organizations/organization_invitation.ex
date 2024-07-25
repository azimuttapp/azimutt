defmodule Azimutt.Organizations.OrganizationInvitation do
  @moduledoc false
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization

  schema "organization_invitations" do
    field :sent_to, :string
    field :role, Ecto.Enum, values: [:owner, :writer, :reader]
    belongs_to :organization, Organization
    field :expire_at, :utc_datetime_usec
    belongs_to :created_by, User, source: :created_by
    timestamps(updated_at: false)
    field :cancel_at, :utc_datetime_usec
    belongs_to :answered_by, User, source: :answered_by
    field :refused_at, :utc_datetime_usec
    field :accepted_at, :utc_datetime_usec
  end

  @doc false
  def create_changeset(organization_invitation, attrs, organization_id, current_user, expire_at) do
    organization_invitation
    |> cast(attrs, [:sent_to, :role])
    |> put_change(:expire_at, expire_at)
    |> put_change(:created_by, current_user)
    |> put_change(:organization_id, organization_id)
    |> validate_required([:sent_to])
  end

  @doc false
  def cancel_changeset(organization_invitation, current_user, now) do
    organization_invitation
    |> cast(%{}, [])
    |> put_change(:cancel_at, now)
    |> put_change(:answered_by, current_user)
  end

  @doc false
  def accept_changeset(organization_invitation, current_user, now) do
    organization_invitation
    |> cast(%{}, [])
    |> put_change(:accepted_at, now)
    |> put_change(:answered_by, current_user)
  end

  @doc false
  def refuse_changeset(organization_invitation, current_user, now) do
    organization_invitation
    |> cast(%{}, [])
    |> put_change(:refused_at, now)
    |> put_change(:answered_by, current_user)
  end
end
