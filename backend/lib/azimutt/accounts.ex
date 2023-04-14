defmodule Azimutt.Accounts do
  @moduledoc "The Accounts context."
  import Ecto.Query, warn: false
  alias Azimutt.Repo
  alias Azimutt.Accounts.{User, UserNotifier, UserProfile, UserToken}
  alias Azimutt.Organizations
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Tracking
  alias Azimutt.Utils.Crypto
  alias Azimutt.Utils.Result

  ## Database getters

  def get_user(id) when is_binary(id) do
    Repo.get(User, id)
    |> Repo.preload([:organizations])
    |> Result.from_nillable()
  end

  def get_user_by_provider(provider, provider_uid) when is_binary(provider) and is_binary(provider_uid) do
    Repo.get_by(User, provider: provider, provider_uid: provider_uid)
    |> Repo.preload([:organizations])
    |> Result.from_nillable()
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
    |> Repo.preload([:organizations])
    |> Result.from_nillable()
  end

  def get_user_by_email_and_password(email, password) when is_binary(email) and is_binary(password) do
    get_user_by_email(email)
    |> Result.filter(fn user -> User.valid_password?(user, password) end, :not_found)
  end

  ## User registration

  def change_user_registration(attrs, %User{} = user, now) do
    User.password_creation_changeset(user, attrs, now, hash_password: false)
  end

  def register_password_user(attrs, attribution, now) do
    %User{}
    |> User.password_creation_changeset(attrs |> with_data(attribution), now)
    |> register_user("password")
  end

  def register_github_user(user_attrs, profile_attrs, attribution, now) do
    %User{}
    |> User.github_creation_changeset(user_attrs |> with_data(attribution), now)
    |> register_user("github")
    |> Result.tap(fn user -> create_profile(user, profile_attrs) end)
  end

  def register_heroku_user(email, attribution, now) do
    attrs = %{
      name: email |> String.split("@") |> hd(),
      email: email,
      avatar: "https://www.gravatar.com/avatar/#{Crypto.md5(email)}?s=150&d=robohash",
      provider: "heroku"
    }

    %User{}
    |> User.heroku_creation_changeset(attrs |> with_data(attribution), now)
    |> register_user("heroku")
  end

  defp with_data(attrs, attribution) do
    attributed_to =
      if attribution do
        attribution["ref"] || attribution["via"] || attribution["utm_source"] || attribution["referer"]
      else
        nil
      end

    attrs |> Map.put(:data, %{attributed_from: attribution["event"], attributed_to: attributed_to})
  end

  defp register_user(changeset, method) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, changeset)
    |> Ecto.Multi.run(:organization, fn _repo, %{user: user} -> Organizations.create_personal_organization(user) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} ->
        Tracking.user_created(user, method, if(user.data, do: user.data.attributed_to, else: nil))

        if Azimutt.config(:global_organization) do
          OrganizationMember.new_member_changeset(Azimutt.config(:global_organization), user) |> Repo.insert()
        end

        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}
    end
  end

  ## Profile

  def set_onboarding(%User{} = user, onboarding, now) do
    user
    |> User.onboarding_changeset(%{onboarding: onboarding})
    |> User.update_changeset(now)
    |> Repo.update()
  end

  def get_or_create_profile(%User{} = user) do
    Repo.get_by(UserProfile, user_id: user.id)
    |> Result.from_nillable()
    |> Result.flat_map_error(fn _ -> create_profile(user, %{}) end)
    |> Result.map(fn p -> p |> Repo.preload(:user) end)
  end

  defp create_profile(%User{} = user, attrs) do
    %UserProfile{}
    |> UserProfile.creation_changeset(user, attrs)
    |> Repo.insert()
  end

  def change_profile_usage(%UserProfile{} = profile, now) do
    profile
    |> UserProfile.usage_changeset(%{}, now)
  end

  def set_profile_usage(%UserProfile{} = profile, usage, now) do
    profile
    |> UserProfile.usage_changeset(%{usage: usage}, now)
    |> Repo.update()
  end

  def change_profile_usecase(%UserProfile{} = profile, now) do
    profile
    |> UserProfile.usecase_changeset(%{}, now)
  end

  def set_profile_usecase(%UserProfile{} = profile, usecase, now) do
    profile
    |> UserProfile.usecase_changeset(%{usecase: usecase}, now)
    |> Repo.update()
  end

  def change_profile_role(%UserProfile{} = profile, now) do
    profile
    |> UserProfile.role_changeset(%{}, now)
  end

  def set_profile_role(%UserProfile{} = profile, role, now) do
    profile
    |> UserProfile.role_changeset(%{role: role}, now)
    |> Repo.update()
  end

  def change_profile_user_attrs(%UserProfile{} = profile, now) do
    profile
    |> UserProfile.about_you_changeset(%{}, now)
  end

  def set_profile_user_attrs(%UserProfile{} = profile, attrs, now) do
    profile
    |> UserProfile.about_you_changeset(attrs, now)
    |> Repo.update()
  end

  def change_profile_company(%UserProfile{} = profile, now) do
    profile
    |> UserProfile.company_changeset(%{}, now)
  end

  def set_profile_company(%UserProfile{} = profile, attrs, now) do
    if attrs["organization"] == "true" do
      Organizations.create_non_personal_organization(
        %{
          name: attrs["organization_name"],
          contact_email: attrs["organization_email"],
          logo: Faker.Avatar.image_url()
        },
        profile.user
      )
      |> Result.map(fn org -> org.id end)
    else
      {:ok, nil}
    end
    |> Result.flat_map(fn organization_id ->
      company_attrs = if organization_id, do: attrs |> Map.put("team_organization_id", organization_id), else: attrs

      profile
      |> UserProfile.company_changeset(company_attrs, now)
      |> Repo.update()
    end)
  end

  def change_profile_plan(%UserProfile{} = profile, now) do
    profile
    |> UserProfile.plan_changeset(%{}, now)
  end

  def set_profile_plan(%UserProfile{} = profile, attrs, now) do
    profile
    |> UserProfile.plan_changeset(attrs, now)
    |> Repo.update()
  end

  def change_profile_previous(%UserProfile{} = profile, now) do
    profile
    |> UserProfile.previous_changeset(%{}, now)
  end

  def set_profile_previous(%UserProfile{} = profile, attrs, now) do
    profile
    |> UserProfile.previous_changeset(attrs, now)
    |> Repo.update()
  end

  ## Settings

  def change_user_infos(%User{} = user, attrs \\ %{}) do
    User.infos_changeset(user, attrs)
  end

  def update_user_infos(%User{} = user, attrs, now) do
    user
    |> User.infos_changeset(attrs)
    |> User.update_changeset(now)
    |> Repo.update()
  end

  def change_user_email(%User{} = user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  def apply_user_email(%User{} = user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  # `user` object has email updated in-memory but not persisted
  def send_email_update(%User{} = user, previous_email, url_fun) when is_function(url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{previous_email}")

    Repo.insert!(user_token)
    UserNotifier.send_email_update(user, previous_email, url_fun.(encoded_token))
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(%User{} = user, token, now) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context, now)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(%User{} = user, email, context, now) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset(now)
      |> User.update_changeset(now)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  def change_user_password(%User{} = user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def update_user_password(%User{} = user, current_password, attrs, now) do
    perform_update_user_password(user, attrs, &User.validate_current_password(&1, current_password), now)
  end

  def set_user_password(%User{} = user, attrs, now) do
    perform_update_user_password(user, attrs, &User.validate_no_password(&1), now)
  end

  defp perform_update_user_password(%User{} = user, attrs, validate, now) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> validate.()
      |> User.update_changeset(now)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def remove_user_password(%User{} = user, now) do
    user
    |> User.remove_password_changeset()
    |> User.update_changeset(now)
    |> Repo.update()
  end

  def set_user_provider(%User{} = user, attrs, now) do
    user
    |> User.provider_changeset(attrs)
    |> User.update_changeset(now)
    |> Repo.update()
  end

  ## Session

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  def send_email_confirmation(%User{} = user, url_fun) when is_function(url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm_email")
      Repo.insert!(user_token)
      UserNotifier.send_email_confirmation(user, url_fun.(encoded_token))
    end
  end

  def confirm_user(%User{} = current_user, token, now) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm_email"),
         %User{} = user <- Repo.one(query),
         :ok <- if(current_user.id == user.id, do: :ok, else: :error),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user, now)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user, now) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user, now))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm_email"]))
  end

  ## Reset password

  def send_password_reset(%User{} = user, url_fun) when is_function(url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.send_password_reset(user, url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def get_user_organizations(%User{} = user) do
    if Azimutt.config(:global_organization) && Azimutt.config(:global_organization_alone) do
      user.organizations |> Enum.filter(fn orga -> orga.id == Azimutt.config(:global_organization) end)
    else
      user.organizations
    end
  end

  def get_user_default_organization(%User{} = user) do
    if Azimutt.config(:global_organization) do
      user.organizations
      |> Enum.filter(fn orga -> orga.id == Azimutt.config(:global_organization) end)
      |> List.first() || get_user_personal_organization(user)
    else
      get_user_personal_organization(user)
    end
  end

  def get_user_personal_organization(%User{} = user) do
    user.organizations
    |> Enum.filter(fn orga -> orga.is_personal == true end)
    |> List.first() || user.organizations |> List.first()
  end
end
