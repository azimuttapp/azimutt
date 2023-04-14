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

  def usage_changeset(%UserProfile{} = p, attrs, now), do: changeset(p, attrs, now, [:usage])
  def usecase_changeset(%UserProfile{} = p, attrs, now), do: changeset(p, attrs, now, [:usecase])
  def role_changeset(%UserProfile{} = p, attrs, now), do: changeset(p, attrs, now, [:role])
  def about_you_changeset(%UserProfile{} = p, attrs, now), do: changeset(p, attrs, now, [:location, :description])
  def company_changeset(%UserProfile{} = p, attrs, now), do: changeset(p, attrs, now, [:company, :company_size], [:team_organization_id])
  def plan_changeset(%UserProfile{} = p, attrs, now), do: changeset(p, attrs, now, [:plan])

  def previous_changeset(%UserProfile{} = p, attrs, now),
    do: changeset(p, attrs, now, [:discovered_by, :previously_tried, :product_updates])

  defp changeset(%UserProfile{} = profile, attrs, now, required, others \\ []) do
    profile
    |> cast(attrs, required ++ others)
    |> change(updated_at: now)
    |> validate_required(required)
  end
end
