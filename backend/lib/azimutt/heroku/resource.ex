defmodule Azimutt.Heroku.Resource do
  @moduledoc "A Resource created by the Heroku addon"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Heroku.Resource
  alias Azimutt.Projects.Project

  schema "heroku_resources" do
    field :heroku_id, Ecto.UUID
    belongs_to :project, Project
    field :name, :string
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
    required = [:heroku_id, :name, :plan, :region, :callback, :oauth_code, :oauth_type, :oauth_expire]

    resource
    |> cast(attrs, required ++ [:options])
    |> validate_required(required)
  end

  def update_plan_changeset(%Resource{} = resource, attrs, now) do
    resource
    |> cast(attrs, [:plan])
    |> validate_required([:plan])
    |> put_change(:updated_at, now)
  end

  def set_project_changeset(%Resource{} = resource, %Project{} = project, now) do
    resource
    |> cast(%{}, [])
    |> put_change(:project, project)
    |> put_change(:updated_at, now)
  end

  def delete_changeset(%Resource{} = resource, now) do
    resource
    |> cast(%{}, [])
    |> put_change(:deleted_at, now)
  end
end
