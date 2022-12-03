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
    belongs_to :created_by, User, source: :created_by
    belongs_to :updated_by, User, source: :updated_by
    timestamps()
  end

  @doc false
  def creator_changeset(%User{} = current_user) do
    %OrganizationMember{}
    |> cast(%{}, [])
    |> put_assoc(:user, current_user)
    |> put_assoc(:created_by, current_user)
    |> put_assoc(:updated_by, current_user)
    |> validate_required([:created_by, :updated_by])
  end

  @doc false
  def new_member_changeset(organization_id, %User{} = current_user) do
    %OrganizationMember{}
    |> cast(%{}, [])
    |> put_assoc(:user, current_user)
    |> put_change(:organization_id, organization_id)
    |> put_assoc(:created_by, current_user)
    |> put_assoc(:updated_by, current_user)
    |> validate_required([:created_by, :updated_by])
  end
end
