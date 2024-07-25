defmodule Azimutt.Accounts.User do
  @moduledoc "User schema"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Accounts.UserProfile
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Utils.Slugme

  schema "users" do
    field :slug, :string
    field :name, :string
    field :email, :string
    field :provider, :string
    field :provider_uid, :string
    field :provider_data, :map
    field :avatar, :string
    field :onboarding, :string
    field :github_username, :string
    field :twitter_username, :string
    field :is_admin, :boolean, default: false
    field :hashed_password, :string, redact: true
    field :password, :string, virtual: true, redact: true
    field :last_signin, :utc_datetime_usec
    embeds_one :data, User.Data, on_replace: :update
    timestamps()
    field :confirmed_at, :utc_datetime_usec
    field :deleted_at, :utc_datetime_usec

    has_one :profile, UserProfile
    has_many :members, OrganizationMember
  end

  def search_fields, do: [:slug, :name, :email, :github_username, :twitter_username]

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_creation_changeset(user, attrs, now, opts \\ []) do
    required = [:name, :email, :avatar]

    user
    |> cast(attrs, required ++ [:password, :github_username, :twitter_username])
    |> Slugme.generate_slug(:name)
    |> validate_email()
    |> validate_password(opts)
    |> setup_onboarding()
    |> put_change(:last_signin, now)
    |> cast_embed(:data, required: true, with: &User.Data.changeset/2)
    |> validate_required(required)
  end

  def github_creation_changeset(user, attrs, now) do
    required = [:name, :email, :avatar, :provider, :provider_uid, :provider_data, :github_username]

    user
    |> cast(attrs, required ++ [:twitter_username, :confirmed_at])
    |> Slugme.generate_slug(:github_username)
    |> setup_onboarding()
    |> put_change(:last_signin, now)
    |> cast_embed(:data, required: true, with: &User.Data.changeset/2)
    |> validate_required(required)
  end

  def heroku_creation_changeset(user, attrs, now) do
    required = [:name, :email, :avatar, :provider, :provider_uid]

    user
    |> cast(attrs, required ++ [:provider_data])
    |> Slugme.generate_slug(:name)
    # |> setup_onboarding() # no onboarding for Heroku users => rework on this
    |> put_change(:last_signin, now)
    |> put_change(:confirmed_at, now)
    |> cast_embed(:data, required: true, with: &User.Data.changeset/2)
    |> validate_required(required)
  end

  def clever_cloud_creation_changeset(user, attrs, now) do
    required = [:name, :email, :avatar, :provider, :provider_uid]

    user
    |> cast(attrs, required ++ [:provider_data])
    |> Slugme.generate_slug(:name)
    # |> setup_onboarding() # no onboarding for Clever Cloud users => rework on this
    |> put_change(:last_signin, now)
    |> put_change(:confirmed_at, now)
    |> cast_embed(:data, required: true, with: &User.Data.changeset/2)
    |> validate_required(required)
  end

  def start_checklist_changeset(user, values) do
    user
    |> cast(%{data: %{start_checklist: values}}, [])
    |> cast_embed(:data, required: true, with: &User.Data.changeset/2)
  end

  defp setup_onboarding(user_changeset) do
    if Azimutt.config(:skip_onboarding_funnel) do
      user_changeset
    else
      user_changeset |> put_change(:onboarding, "welcome")
    end
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_ends_with(:email, Azimutt.config(:require_email_ends_with))
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Azimutt.Repo)
    |> unique_constraint(:email)
  end

  defp validate_ends_with(changeset, field, suffix) do
    if suffix do
      regex = "#{Regex.escape(suffix)}$" |> Regex.compile!()
      changeset |> validate_format(field, regex, message: "must ends with '#{suffix}'")
    else
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def infos_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :avatar])
    |> validate_required([:name, :avatar])
  end

  def onboarding_changeset(user, attrs) do
    user
    |> cast(attrs, [:onboarding])
  end

  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def remove_password_changeset(user) do
    user
    |> cast(%{hashed_password: nil}, [:hashed_password])
  end

  def provider_changeset(user, attrs) do
    user
    |> cast(attrs, [:provider, :provider_uid, :provider_data])
  end

  @doc "Confirms the account by setting `confirmed_at`."
  def confirm_changeset(user, now) do
    user |> change(confirmed_at: now)
  end

  def update_changeset(user, now) do
    user |> change(updated_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Azimutt.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc "Validates the current password otherwise adds an error to the changeset."
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def validate_no_password(changeset) do
    if changeset.data.hashed_password == nil do
      changeset
    else
      add_error(changeset, :current_password, "should not be set")
    end
  end
end
