defmodule Azimutt.Organizations.Organization do
  @moduledoc "The organization schema"
  use Ecto.Schema
  use Azimutt.Schema
  use TypedStruct
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.CleverCloud
  alias Azimutt.Heroku
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationInvitation
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Slugme

  schema "organizations" do
    field :slug, :string
    field :name, :string
    field :logo, :string
    field :description, :string
    field :github_username, :string
    field :twitter_username, :string
    field :stripe_customer_id, :string
    field :stripe_subscription_id, :string
    field :is_personal, :boolean
    embeds_one :data, Organization.Data, on_replace: :update
    belongs_to :created_by, User, source: :created_by
    belongs_to :updated_by, User, source: :updated_by
    timestamps()
    belongs_to :deleted_by, User, source: :deleted_by
    field :deleted_at, :utc_datetime_usec

    has_many :members, OrganizationMember, on_replace: :delete
    has_many :projects, Project
    has_many :invitations, OrganizationInvitation
    has_one :clever_cloud_resource, CleverCloud.Resource
    has_one :heroku_resource, Heroku.Resource
  end

  def search_fields,
    do: [
      :slug,
      :name,
      :description,
      :github_username,
      :twitter_username,
      :stripe_customer_id
    ]

  @doc false
  def create_personal_changeset(%Organization{} = organization, %User{} = current_user) do
    required = [:name, :logo]

    organization
    |> cast(
      %{
        name: current_user.name,
        logo: current_user.avatar,
        github_username: current_user.github_username,
        twitter_username: current_user.twitter_username
      },
      required ++ [:description, :github_username, :twitter_username]
    )
    |> Slugme.generate_slug(:name)
    |> put_change(:is_personal, true)
    |> put_assoc(:created_by, current_user)
    |> put_assoc(:updated_by, current_user)
    |> validate_required(required)
    |> unique_constraint(:slug)
  end

  @doc false
  def create_non_personal_changeset(%Organization{} = organization, %User{} = current_user, attrs \\ %{}) do
    required = [:name, :logo]

    organization
    |> cast(attrs, required ++ [:description, :github_username, :twitter_username])
    |> Slugme.generate_slug(:name)
    |> put_change(:is_personal, false)
    |> put_change(:created_by, current_user)
    |> put_change(:updated_by, current_user)
    |> validate_required(required)
    |> unique_constraint(:slug)
  end

  @doc false
  def add_stripe_customer_changeset(%Organization{} = organization, %Stripe.Customer{} = stripe_customer) do
    organization
    |> cast(%{}, [])
    |> put_change(:stripe_customer_id, stripe_customer.id)
  end

  @doc false
  def accept_invitation_changeset(%Organization{} = organization, %User{} = invited_user) do
    organization
    |> cast(%{}, [])
    |> put_assoc(:members, [invited_user | organization.members])
  end

  @doc false
  def update_changeset(%Organization{} = organization, attrs \\ %{}, %User{} = current_user) do
    organization
    |> cast(attrs, [
      :name,
      :logo,
      :description,
      :github_username,
      :twitter_username
    ])
    |> put_change(:updated_by_id, current_user.id)
  end

  def delete_changeset(%Organization{} = organization, now) do
    organization
    |> cast(%{}, [])
    |> put_change(:deleted_at, now)
  end

  def allow_table_color_changeset(%Organization{} = organization, tweet_url) do
    organization
    |> cast(%{data: %{allow_table_color: tweet_url}}, [])
    |> cast_embed(:data, required: true, with: &data_allow_table_color_changeset/2)
  end

  defp data_allow_table_color_changeset(%Organization.Data{} = data, attrs) do
    data
    |> cast(attrs, [:allow_table_color])
    |> validate_required([:allow_table_color])
  end
end
