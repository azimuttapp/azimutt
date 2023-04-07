defmodule Azimutt.Accounts.UserProfile do
  @moduledoc "User profile schema"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User

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
end
