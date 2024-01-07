defmodule Azimutt.Accounts.UserAuthToken do
  @moduledoc "Auth tokens allowing to identify a user simply by passing this token"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Utils.Uuid

  schema "user_auth_tokens" do
    belongs_to :user, User
    field :name, :string
    field :nb_access, :integer
    field :last_access, :utc_datetime_usec
    field :expire_at, :utc_datetime_usec
    timestamps(updated_at: false)
    field :deleted_at, :utc_datetime_usec
  end

  def create_changeset(token, attrs) do
    token
    |> cast(attrs, [:name, :expire_at])
    |> put_change(:user_id, attrs.user_id)
    |> put_change(:nb_access, 0)
    |> validate_required([:name])
  end

  def access_changeset(token, now) do
    token
    |> cast(%{last_access: now, nb_access: token.nb_access + 1}, [:last_access, :nb_access])
  end

  def delete_changeset(token, now) do
    token
    |> cast(%{deleted_at: now}, [:deleted_at])
  end

  def is_valid?(value), do: Uuid.is_valid?(value)
end
