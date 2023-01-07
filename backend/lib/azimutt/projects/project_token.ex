defmodule Azimutt.Projects.ProjectToken do
  @moduledoc "Grant access to a project without being in the organization or even logged"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Projects.Project

  schema "project_tokens" do
    belongs_to :project, Project
    field :nb_access, :integer
    field :last_access, :utc_datetime_usec
    field :expire_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    belongs_to :revoked_by, User, source: :revoked_by
    timestamps(updated_at: false)
    belongs_to :created_by, User, source: :created_by
  end
end
