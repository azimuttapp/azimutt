defmodule Azimutt.Organizations.OrganizationMember do
  @moduledoc false
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationMember

  @primary_key false
  schema "organization_members" do
    belongs_to :user, User, primary_key: true
    belongs_to :organization, Organization, primary_key: true
    field :role, Ecto.Enum, values: [:owner, :writer, :reader]
    belongs_to :created_by, User, source: :created_by
    belongs_to :updated_by, User, source: :updated_by
    timestamps()
  end

  def owner, do: :owner
  def writer, do: :writer
  def reader, do: :reader
  def roles, do: [Owner: OrganizationMember.owner(), Writer: OrganizationMember.writer(), Reader: OrganizationMember.reader()]

  @doc false
  def creator_changeset(%User{} = current_user) do
    %OrganizationMember{}
    |> cast(%{role: OrganizationMember.owner()}, [:role])
    |> put_assoc(:user, current_user)
    |> put_assoc(:created_by, current_user)
    |> put_assoc(:updated_by, current_user)
  end

  @doc false
  def new_member_changeset(organization_id, %User{} = current_user, role) do
    %OrganizationMember{}
    |> cast(%{role: if(is_binary(role), do: role, else: OrganizationMember.owner())}, [:role])
    |> put_assoc(:user, current_user)
    |> put_change(:organization_id, organization_id)
    |> put_assoc(:created_by, current_user)
    |> put_assoc(:updated_by, current_user)
  end

  def update_role_changeset(%OrganizationMember{} = member, role, now, %User{} = current_user) do
    member
    |> cast(%{}, [])
    |> put_change(:role, String.to_atom(role))
    |> put_change(:updated_at, now)
    |> put_change(:updated_by_id, current_user.id)
  end
end
