defmodule Azimutt.Accounts.UserProfile do
  @moduledoc "User profile schema"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Accounts.UserProfile
  alias Azimutt.Organizations.Organization

  schema "user_profiles" do
    belongs_to :user, User
    field :usage, Ecto.Enum, values: [:solo, :team]
    field :usecase, Ecto.Enum, values: [:design, :explore]
    field :role, :string
    field :location, :string
    field :description, :string
    field :company, :string
    field :company_size, :integer
    belongs_to :team_organization, Organization
    field :plan, :string
    field :discovered_by, :string
    field :previously_tried, {:array, :string}
    field :product_updates, :boolean
    timestamps()
  end

  def creation_changeset(%UserProfile{} = profile, %User{} = user, attrs) do
    profile
    |> cast(attrs, [
      :usage,
      :usecase,
      :role,
      :location,
      :description,
      :company,
      :company_size,
      :plan,
      :discovered_by,
      :previously_tried,
      :product_updates
    ])
    |> put_change(:user, user)
  end

  def usage_changeset(%UserProfile{} = profile, attrs, now) do
    required = [:usage]

    profile
    |> cast(attrs, required)
    |> change(updated_at: now)
    |> validate_required(required)
  end

  def usecase_changeset(%UserProfile{} = profile, attrs, now) do
    required = [:usecase]

    profile
    |> cast(attrs, required)
    |> change(updated_at: now)
    |> validate_required(required)
  end

  def role_changeset(%UserProfile{} = profile, attrs, now) do
    required = [:role]

    profile
    |> cast(attrs, required)
    |> change(updated_at: now)
    |> validate_required(required)
  end

  def about_you_changeset(%UserProfile{} = profile, attrs, now) do
    required = [:location, :description]

    profile
    |> cast(attrs, required)
    |> change(updated_at: now)
    |> validate_required(required)
  end

  def company_changeset(%UserProfile{} = profile, attrs, now) do
    required = [:company, :company_size, :team_organization_id]

    profile
    |> cast(attrs, required)
    |> change(updated_at: now)
    |> validate_required(required)
  end
end
