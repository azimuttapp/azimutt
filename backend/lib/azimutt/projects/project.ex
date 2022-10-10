defmodule Azimutt.Projects.Project do
  @moduledoc "The project schema, contains some metadata about the project"
  use Ecto.Schema
  use Azimutt.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Slugme

  schema "projects" do
    belongs_to :organization, Organization
    field :slug, :string
    field :name, :string
    field :description, :string
    field :encoding_version, :integer
    field :storage_kind, Ecto.Enum, values: [:local, :remote]
    field :file, Azimutt.Projects.ProjectFile.Type
    belongs_to :local_owner, User, source: :local_owner
    field :nb_sources, :integer
    field :nb_tables, :integer
    field :nb_columns, :integer
    field :nb_relations, :integer
    # number of SQL custom types in the project
    field :nb_types, :integer
    # number of SQL comments in the project
    field :nb_comments, :integer
    field :nb_notes, :integer
    field :nb_layouts, :integer
    belongs_to :created_by, User, source: :created_by
    belongs_to :updated_by, User, source: :updated_by
    timestamps()
    belongs_to :archived_by, User, source: :archived_by
    field :archived_at, :utc_datetime_usec
  end

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
      :nb_notes,
      :nb_layouts
    ]

    %Project{}
    |> cast(attrs, required ++ [:description])
    |> put_change(:id, uuid)
    |> Slugme.generate_slug(:name)
    |> put_change(:organization, organization)
    |> put_change(:storage_kind, Storage.local())
    |> put_change(:local_owner, current_user)
    |> put_change(:created_by, current_user)
    |> put_change(:updated_by, current_user)
    |> validate_required(required)
  end

  @doc false
  def create_azimutt_changeset(attrs, %Organization{} = organization, %User{} = current_user, uuid) do
    required = [
      :name,
      :encoding_version,
      :nb_sources,
      :nb_tables,
      :nb_columns,
      :nb_relations,
      :nb_types,
      :nb_comments,
      :nb_notes,
      :nb_layouts
    ]

    %Project{}
    |> cast(attrs, required ++ [:description])
    |> put_change(:id, uuid)
    |> Slugme.generate_slug(:name)
    |> cast_attachments(attrs, [:file])
    |> put_change(:organization, organization)
    |> put_change(:storage_kind, Storage.remote())
    |> put_change(:created_by, current_user)
    |> put_change(:updated_by, current_user)
    |> validate_required(required)
  end

  @doc false
  def update_local_changeset(%Project{} = project, attrs, %User{} = current_user) do
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
      :nb_notes,
      :nb_layouts
    ]

    project
    |> cast(attrs, required ++ [:description])
    |> put_change(:updated_by_id, current_user.id)
    |> validate_required(required)
  end

  @doc false
  def update_azimutt_changeset(%Project{} = project, attrs, %User{} = current_user) do
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
      :nb_notes,
      :nb_layouts
    ]

    project
    |> cast(attrs, required ++ [:description])
    |> cast_attachments(attrs, [:file])
    |> put_change(:updated_by_id, current_user.id)
    |> validate_required(required)
  end
end
