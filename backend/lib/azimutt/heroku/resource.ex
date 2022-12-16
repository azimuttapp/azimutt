defmodule Azimutt.Heroku.Resource do
  @moduledoc "A Resource created by the Heroku addon"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Heroku.Resource
  alias Azimutt.Organizations.Organization

  schema "heroku_resources" do
    belongs_to :organization, Organization
    field :name, :string
    field :app, :string
    field :plan, :string
    field :region, :string
    field :options, :map
    field :callback, :string
    field :oauth_code, Ecto.UUID
    field :oauth_type, :string
    field :oauth_expire, :utc_datetime_usec
    timestamps()
    field :deleted_at, :utc_datetime_usec
  end

  def create_changeset(%Resource{} = resource, attrs) do
    required = [:id, :name, :plan, :region, :callback, :oauth_code, :oauth_type, :oauth_expire]

    resource
    |> cast(attrs, required ++ [:options])
    |> validate_required(required)
  end

  def update_app_changeset(%Resource{} = resource, app, now) do
    resource
    |> cast(%{app: app}, [:app])
    |> put_change(:updated_at, now)
    |> validate_required([:app])
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
