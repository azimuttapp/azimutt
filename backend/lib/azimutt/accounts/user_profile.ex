defmodule Azimutt.Accounts.UserProfile do
  @moduledoc "User profile schema"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Accounts.UserProfile

  schema "user_profiles" do
    belongs_to :user, User
    field :initial_usage, Ecto.Enum, values: [:solo, :team]
    field :initial_usecase, Ecto.Enum, values: [:design, :explore]
    field :role, :string
    field :company_size, :integer
    field :discovered_by, :string
    field :previously_tried, :string
    field :product_updates, :boolean
    timestamps()
  end

  def creation_changeset(%UserProfile{} = profile, %User{} = user) do
    required = [:user_id]

    profile
    |> cast(%{user_id: user.id}, required)
    |> validate_required(required)
  end

  def usage_changeset(%UserProfile{} = profile, attrs, now) do
    required = [:initial_usage]

    profile
    |> cast(attrs, required)
    |> change(updated_at: now)
    |> validate_required(required)
  end

  def usecase_changeset(%UserProfile{} = profile, attrs, now) do
    required = [:initial_usecase]

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
end
