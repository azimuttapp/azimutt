defmodule Azimutt.Projects.Project do
  @moduledoc "The project schema, contains some metadata about the project"
  use Ecto.Schema
  use Azimutt.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project
  alias Azimutt.Projects.ProjectFile
  alias Azimutt.Utils.Slugme

  schema "projects" do
    belongs_to :organization, Organization
    field :slug, :string
    field :name, :string
    field :description, :string
    field :encoding_version, :integer
    field :storage_kind, Ecto.Enum, values: [:local, :remote]
    field :file, ProjectFile.Type
    belongs_to :local_owner, User, source: :local_owner
    field :visibility, Ecto.Enum, values: [:none, :read, :write]
    field :nb_sources, :integer
    field :nb_tables, :integer
    field :nb_columns, :integer
    field :nb_relations, :integer
    # number of SQL custom types in the project
    field :nb_types, :integer
    # number of SQL comments in the project
    field :nb_comments, :integer
    field :nb_layouts, :integer
    field :nb_notes, :integer
    field :nb_memos, :integer
    belongs_to :created_by, User, source: :created_by
    belongs_to :updated_by, User, source: :updated_by
    timestamps()
    belongs_to :archived_by, User, source: :archived_by
    field :archived_at, :utc_datetime_usec
  end

  def search_fields, do: [:slug, :name, :description]

  defmodule Storage do
    @moduledoc false
    def local, do: :local
    def remote, do: :remote

    def from_string_or_atom(storage) do
      cond do
        storage == :local || storage == "local" -> :local
        storage == :remote || storage == "remote" -> :remote
        true -> raise "Invalid storage: '#{storage}'"
      end
    end
  end

  @doc false
  def create_local_changeset(attrs, %Organization{} = organization, %User{} = current_user, uuid) do
    required = [
      :name,
      :encoding_version,
      :nb_sources,
      :nb_tables,
      :nb_columns,
      :nb_relations,
      :nb_types,
      :nb_comments,
      :nb_layouts,
      :nb_notes,
      :nb_memos
    ]

    %Project{}
    |> cast(attrs, required ++ [:description])
    |> put_change(:id, uuid)
    |> Slugme.generate_slug(:name)
    |> put_change(:organization, organization)
    |> put_change(:storage_kind, Storage.local())
    |> put_change(:local_owner, current_user)
    |> put_change(:visibility, :none)
    |> put_change(:created_by, current_user)
    |> put_change(:updated_by, current_user)
    |> validate_required(required)
  end

  @doc false
  def create_remote_changeset(attrs, %Organization{} = organization, %User{} = current_user, uuid) do
    required = [
      :name,
      :encoding_version,
      :nb_sources,
      :nb_tables,
      :nb_columns,
      :nb_relations,
      :nb_types,
      :nb_comments,
      :nb_layouts,
      :nb_notes,
      :nb_memos
    ]

    %Project{}
    |> cast(attrs, required ++ [:description])
    |> put_change(:id, uuid)
    |> Slugme.generate_slug(:name)
    |> cast_attachments(attrs, [:file])
    |> put_change(:organization, organization)
    |> put_change(:storage_kind, Storage.remote())
    |> put_change(:visibility, :none)
    |> put_change(:created_by, current_user)
    |> put_change(:updated_by, current_user)
    |> validate_required(required)
  end

  @doc false
  def update_local_changeset(%Project{} = project, attrs, %User{} = current_user, now) do
    # FIXME: check that current_user == local_owner
    required = [
      :name,
      :encoding_version,
      :storage_kind,
      :nb_sources,
      :nb_tables,
      :nb_columns,
      :nb_relations,
      :nb_types,
      :nb_comments,
      :nb_layouts,
      :nb_notes,
      :nb_memos
    ]

    project
    |> cast(attrs, required ++ [:description])
    |> put_change(:updated_by_id, current_user.id)
    |> put_change(:updated_at, now)
    |> validate_required(required)
  end

  @doc false
  def update_remote_changeset(%Project{} = project, attrs, %User{} = current_user, now) do
    required = [
      :name,
      :encoding_version,
      :storage_kind,
      :nb_sources,
      :nb_tables,
      :nb_columns,
      :nb_relations,
      :nb_types,
      :nb_comments,
      :nb_layouts,
      :nb_notes,
      :nb_memos
    ]

    project
    |> cast(attrs, required ++ [:description])
    |> cast_attachments(attrs, [:file])
    |> put_change(:updated_by_id, current_user.id)
    |> put_change(:updated_at, now)
    |> validate_required(required)
  end

  def update_project_file_changeset(%Project{} = project, content, %User{} = current_user, now) do
    upload = %{
      content_type: "application/json",
      filename: project.file.file_name,
      binary: content
    }

    project
    |> cast_attachments(%{file: upload}, [:file])
    |> put_change(:updated_by_id, current_user.id)
    |> put_change(:updated_at, now)
  end
end
