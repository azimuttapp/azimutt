defmodule Azimutt.AccountsTest do
  use Azimutt.DataCase
  alias Azimutt.Accounts
  alias Azimutt.Accounts.User
  alias Azimutt.Accounts.UserToken
  import Azimutt.AccountsFixtures

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      assert {:error, :not_found} = Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert {:ok, %User{id: ^id}} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      assert {:error, :not_found} = Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      assert {:error, :not_found} = Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()
      assert {:ok, %User{id: ^id}} = Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user/1" do
    test "return error if id is invalid" do
      assert {:error, :not_found} = Accounts.get_user("bf4176c5-4439-4316-81e1-7a6e2320b141")
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert {:ok, %User{id: ^id}} = Accounts.get_user(user.id)
    end
  end

  describe "register_password_user/1" do
    @tag :skip
    test "requires email and password to be set" do
      now = DateTime.utc_now()
      {:error, changeset} = Accounts.register_password_user(%{}, [], now)

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    @tag :skip
    test "validates email and password when given" do
      now = DateTime.utc_now()
      {:error, changeset} = Accounts.register_password_user(%{email: "not valid", password: "not valid"}, [], now)

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    @tag :skip
    test "validates maximum values for email and password for security" do
      now = DateTime.utc_now()
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Accounts.register_password_user(%{email: too_long, password: too_long}, [], now)

      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    @tag :skip
    test "validates email uniqueness" do
      now = DateTime.utc_now()
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_password_user(%{email: email}, [], now)
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_password_user(%{email: String.upcase(email)}, [], now)
      assert "has already been taken" in errors_on(changeset).email
    end

    @tag :skip
    test "registers users with a hashed password" do
      now = DateTime.utc_now()
      email = unique_user_email()
      {:ok, user} = Accounts.register_password_user(valid_user_attributes(email: email), [], now)
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    @tag :skip
    test "returns a changeset" do
      now = DateTime.utc_now()
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%{}, %User{}, now)
      assert changeset.required == [:password, :email]
    end

    @tag :skip
    test "allows fields to be set" do
      now = DateTime.utc_now()
      email = unique_user_email()
      password = valid_user_password()
      attrs = valid_user_attributes(email: email, password: password)
      changeset = Accounts.change_user_registration(attrs, %User{}, now)

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_email/2" do
    @tag :skip
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: user_fixture()}
    end

    @tag :skip
    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    @tag :skip
    test "validates email", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    @tag :skip
    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    @tag :skip
    test "validates email uniqueness", %{user: user} do
      %{email: email} = user_fixture()

      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    @tag :skip
    test "validates current password", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, "invalid", %{email: unique_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end
  end

  describe "send_email_update/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token = extract_user_token(fn url -> Accounts.send_email_update(user, "current@example.com", url) end)
      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/3" do
    setup do
      user = user_fixture()
      email = unique_user_email()
      token = extract_user_token(fn url -> Accounts.send_email_update(%{user | email: email}, user.email, url) end)
      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      now = DateTime.utc_now()
      assert Accounts.update_user_email(user, token, now) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      now = DateTime.utc_now()
      assert Accounts.update_user_email(user, "oops", now) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      now = DateTime.utc_now()
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token, now) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      now = DateTime.utc_now()
      {1, nil} = Repo.update_all(UserToken, set: [created_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, token, now) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(%User{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/4" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      now = DateTime.utc_now()
      attrs = %{password: "not valid", password_confirmation: "another"}
      {:error, changeset} = Accounts.update_user_password(user, valid_user_password(), attrs, now)

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      now = DateTime.utc_now()
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.update_user_password(user, valid_user_password(), %{password: too_long}, now)

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      now = DateTime.utc_now()
      {:error, changeset} = Accounts.update_user_password(user, "invalid", %{password: valid_user_password()}, now)

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      now = DateTime.utc_now()
      {:ok, user} = Accounts.update_user_password(user, valid_user_password(), %{password: "new valid password"}, now)

      assert is_nil(user.password)
      assert {:ok, _} = Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      now = DateTime.utc_now()
      _ = Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.update_user_password(user, valid_user_password(), %{password: "new valid password"}, now)

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "create_auth_token/3" do
    setup do
      %{user: user_fixture()}
    end

    test "create, access and delete auth token", %{user: user} do
      now = DateTime.utc_now()
      assert Accounts.list_auth_tokens(user, now) == []

      {:ok, token} = Accounts.create_auth_token(user, now, %{"name" => "test"})
      user_token = Accounts.list_auth_tokens(user, now) |> hd()
      assert user_token.id == token.id
      assert user_token.name == "test"
      assert user_token.nb_access == 0
      assert user_token.last_access == nil

      {:ok, fetched_user} = Accounts.get_user_by_auth_token(token.id, now)
      assert fetched_user.id == user.id
      accessed_token = Accounts.list_auth_tokens(user, now) |> hd()
      assert accessed_token.nb_access == 1
      assert accessed_token.last_access == now

      {:ok, _deleted} = Accounts.delete_auth_token(token.id, user, now)
      assert Accounts.list_auth_tokens(user, now) == []
      {:error, :not_found} = Accounts.get_user_by_auth_token(token.id, now)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    @tag :skip
    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    @tag :skip
    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    @tag :skip
    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    @tag :skip
    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    @tag :skip
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "send_email_confirmation/2" do
    setup do
      %{user: user_fixture()}
    end

    @tag :skip
    test "sends token through notification", %{user: user} do
      token = extract_user_token(fn url -> Accounts.send_email_confirmation(user, url) end)
      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm_email"
    end
  end

  describe "confirm_user/3" do
    setup do
      user = user_fixture()
      token = extract_user_token(fn url -> Accounts.send_email_confirmation(user, url) end)
      %{user: user, token: token}
    end

    @tag :skip
    test "confirms the email with a valid token", %{user: user, token: token} do
      now = DateTime.utc_now()
      assert {:ok, confirmed_user} = Accounts.confirm_user(%User{}, token, now)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(User, user.id).confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    @tag :skip
    test "does not confirm with invalid token", %{user: user} do
      now = DateTime.utc_now()
      assert Accounts.confirm_user(%User{}, "oops", now) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    @tag :skip
    test "does not confirm email if token expired", %{user: user, token: token} do
      now = DateTime.utc_now()
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_user(%User{}, token, now) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "send_password_reset/2" do
    setup do
      %{user: user_fixture()}
    end

    @tag :skip
    test "sends token through notification", %{user: user} do
      token = extract_user_token(fn url -> Accounts.send_password_reset(user, url) end)
      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = user_fixture()
      token = extract_user_token(fn url -> Accounts.send_password_reset(user, url) end)
      %{user: user, token: token}
    end

    @tag :skip
    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    @tag :skip
    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    @tag :skip
    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    @tag :skip
    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    @tag :skip
    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    @tag :skip
    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "new valid password"})
      assert is_nil(updated_user.password)
      assert {:ok, _} = Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    @tag :skip
    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.reset_user_password(user, %{password: "new valid password"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "inspect/2" do
    @tag :skip
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
