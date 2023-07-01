defmodule Azimutt.CleverCloud.Resource do
  @moduledoc "A Resource created by the Clever Cloud addon"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.CleverCloud.Resource
  alias Azimutt.Organizations.Organization

  schema "clever_cloud_resources" do
    belongs_to :organization, Organization
    field :addon_id, :string
    field :owner_id, :string
    field :owner_name, :string
    field :user_id, :string
    field :plan, :string
    field :region, :string
    field :callback_url, :string
    field :logplex_token, :string
    field :options, :map
    timestamps()
    field :deleted_at, :utc_datetime_usec
  end

  def create_changeset(%Resource{} = resource, attrs) do
    required = [:addon_id, :owner_id, :owner_name, :user_id, :plan, :region, :callback_url, :logplex_token]

    resource
    |> cast(attrs, required ++ [:options])
    |> validate_required(required)
  end

  def update_organization_changeset(%Resource{} = resource, %Organization{} = organization, now) do
    resource
    |> cast(%{}, [])
    |> put_change(:organization, organization)
    |> put_change(:updated_at, now)
  end

  def update_plan_changeset(%Resource{} = resource, attrs, now) do
    resource
    |> cast(attrs, [:plan])
    |> validate_required([:plan])
    |> put_change(:updated_at, now)
  end

  def delete_changeset(%Resource{} = resource, now) do
    resource
    |> cast(%{}, [])
    |> put_change(:deleted_at, now)
  end
end
