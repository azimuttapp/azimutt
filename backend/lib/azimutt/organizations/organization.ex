defmodule Azimutt.Organizations.Organization do
  @moduledoc """
  The organization schema
  """
  use Ecto.Schema
  use Azimutt.Schema

  import Ecto.Changeset

  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationInvitation
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Slugme

  schema "organizations" do
    field :slug, :string
    field :name, :string
    field :contact_email, :string
    field :active_plan, Ecto.Enum, values: [:free, :team, :enterprise], default: :free
    field :logo, :string
    field :location, :string
    field :description, :string
    field :github_username, :string
    field :twitter_username, :string
    field :is_personal, :boolean
    belongs_to :created_by, User, source: :created_by
    belongs_to :updated_by, User, source: :updated_by
    timestamps()
    belongs_to :deleted_by, User, source: :deleted_by
    field :deleted_at, :utc_datetime_usec

    has_many :members, OrganizationMember, on_replace: :delete
    has_many :projects, Project
    has_many :invitations, OrganizationInvitation
  end

  @doc false
  def create_personal_changeset(%Organization{} = organization, %User{} = current_user) do
    organization
    |> cast(
      %{
        slug: current_user.slug,
        name: current_user.name,
        contact_email: current_user.email,
        logo: current_user.avatar,
        location: current_user.location,
        description: "#{current_user.description}'s organization",
        github_username: current_user.github_username,
        twitter_username: current_user.twitter_username
      },
      [
        :slug,
        :name,
        :contact_email,
        :logo,
        :location,
        :description,
        :github_username,
        :twitter_username
      ]
    )
    |> put_change(:active_plan, :free)
    |> put_change(:is_personal, true)
    |> put_assoc(:created_by, current_user)
    |> put_assoc(:updated_by, current_user)
  end

  @doc false
  def create_non_personal_changeset(
        %Organization{} = organization,
        attrs \\ %{},
        %User{} = current_user
      ) do
    organization
    |> cast(attrs, [
      :name,
      :contact_email,
      :logo,
      :location,
      :description,
      :github_username,
      :twitter_username
    ])
    |> Slugme.generate_slug(:name)
    |> put_change(:active_plan, :free)
    |> put_change(:is_personal, false)
    |> put_change(:created_by, current_user)
    |> put_change(:updated_by, current_user)
    |> validate_required([:name, :contact_email])
  end

  @doc false
  def accept_invitation_changeset(%Organization{} = organization, %User{} = invited_user) do
    organization
    |> cast(%{}, [])
    |> put_assoc(:members, [invited_user | organization.members])
  end

  @doc false
  def update_changeset(
        %Organization{} = organization,
        attrs \\ %{},
        %User{} = current_user
      ) do
    organization
    |> cast(attrs, [
      :name,
      :contact_email,
      :logo,
      :location,
      :description,
      :github_username,
      :twitter_username
    ])
    |> put_change(:updated_by, current_user)
  end
end
