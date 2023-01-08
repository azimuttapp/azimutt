defmodule Azimutt.Projects.ProjectToken do
  @moduledoc "Grant access to a project without being in the organization or even logged"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Projects.Project

  schema "project_tokens" do
    belongs_to :project, Project
    field :name, :string
    field :nb_access, :integer
    field :last_access, :utc_datetime_usec
    field :expire_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    belongs_to :revoked_by, User, source: :revoked_by
    timestamps(updated_at: false)
    belongs_to :created_by, User, source: :created_by
  end

  @doc false
  def create_changeset(token, attrs) do
    token
    |> cast(attrs, [:name, :expire_at])
    |> put_change(:project_id, attrs.project_id)
    |> put_change(:nb_access, 0)
    |> put_change(:created_by, attrs.created_by)
    |> validate_required([:name])
  end

  @doc false
  def access_changeset(token, now) do
    token
    |> cast(%{last_access: now, nb_access: token.nb_access + 1}, [:last_access, :nb_access])
  end

  @doc false
  def revoke_changeset(token, %User{} = current_user, now) do
    token
    |> cast(%{revoked_at: now}, [:revoked_at])
    |> put_change(:revoked_by, current_user)
  end
end
