defmodule Azimutt.Audit.Event do
  @moduledoc "The audit event schema"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project

  schema "audit" do
    field :name, Ecto.Enum, values: [:project_loaded, :project_created, :project_updated, :project_deleted]
    field :details, :map
    belongs_to :created_by, User, source: :created_by
    timestamps(updated_at: false)
    belongs_to :organization, Organization
    belongs_to :project, Project
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :details])
    |> put_change(:created_by, attrs.created_by)
    |> put_change(:organization_id, attrs.organization_id)
    |> put_change(:project_id, attrs.project_id)
    |> validate_required([:name, :created_by])
  end
end
