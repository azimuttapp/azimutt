defmodule AzimuttWeb.UserSettingsController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Utils.Result
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  def show(conn, _params) do
    current_user = conn.assigns.current_user
    conn |> show_html(current_user)
  end

  def update_account(conn, %{"user" => user_params}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    Accounts.update_user_infos(current_user, user_params, now)
    |> Result.fold(
      fn changeset_error -> conn |> show_html(current_user, infos_changeset: changeset_error) end,
      fn _ -> conn |> put_flash(:info, "Infos updated!") |> redirect(to: Routes.user_settings_path(conn, :show)) end
    )
  end

  # FIXME: how to change email for users from social login? (no password)
  def update_email(conn, %{"user" => user_params}) do
    current_user = conn.assigns.current_user

    Accounts.apply_user_email(current_user, user_params["current_password"], user_params)
    |> Result.fold(
      fn changeset_error -> conn |> show_html(current_user, email_changeset: changeset_error) end,
      fn user ->
        {flash_kind, flash_message} =
          Accounts.send_email_update(user, current_user.email, &Routes.user_settings_url(conn, :confirm_update_email, &1))
          |> Result.fold(
            fn _ -> {:error, "Error while sending you the email, please contact #{Azimutt.config(:support_email)}"} end,
            fn _ -> {:info, "Email sent at your current address, click on the link to confirm your email change."} end
          )

        conn |> put_flash(flash_kind, flash_message) |> redirect(to: Routes.user_settings_path(conn, :show))
      end
    )
  end

  def confirm_update_email(conn, %{"token" => token}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    {flash_kind, flash_message} =
      Accounts.update_user_email(current_user, token, now)
      |> Result.fold(
        fn _ -> {:error, "Error while updating your email, please contact #{Azimutt.config(:support_email)}"} end,
        fn _ -> {:info, "Your email is now successfully updated 👏"} end
      )

    conn |> put_flash(flash_kind, flash_message) |> redirect(to: Routes.user_settings_path(conn, :show))
  end

  def update_password(conn, %{"user" => user_params}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    Accounts.update_user_password(current_user, user_params["current_password"], user_params, now)
    |> Result.fold(
      fn changeset_error -> conn |> show_html(current_user, password_changeset: changeset_error) end,
      fn user ->
        conn
        |> UserAuth.login_user(user, "update_password")
        |> put_flash(:info, "Password updated!")
        |> redirect(to: Routes.user_settings_path(conn, :show))
      end
    )
  end

  def set_password(conn, %{"user" => user_params}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    Accounts.set_user_password(current_user, user_params, now)
    |> Result.fold(
      fn _changeset_error ->
        conn
        |> put_flash(:error, "Failed to set password 😕")
        |> redirect(to: Routes.user_settings_path(conn, :show))
      end,
      fn user ->
        conn
        |> UserAuth.login_user(user, "set_password")
        |> put_flash(:info, "Password created!")
        |> redirect(to: Routes.user_settings_path(conn, :show))
      end
    )
  end

  def remove_provider(conn, %{"provider" => provider}) do
    current_user = conn.assigns.current_user
    now = DateTime.utc_now()

    if provider == "password" do
      Accounts.remove_user_password(current_user, now)
    else
      Accounts.set_user_provider(current_user, %{provider: nil, provider_uid: nil}, now)
    end
    |> Result.fold(
      fn _changeset_error ->
        conn |> put_flash(:error, "Can't remove #{provider} auth 😕") |> redirect(to: Routes.user_settings_path(conn, :show))
      end,
      fn _user ->
        conn |> put_flash(:info, "Removed #{provider} auth!") |> redirect(to: Routes.user_settings_path(conn, :show))
      end
    )
  end

  defp show_html(conn, user, options \\ []) do
    defaults = [
      infos_changeset: Accounts.change_user_infos(user),
      email_changeset: Accounts.change_user_email(user),
      password_changeset: Accounts.change_user_password(user)
    ]

    %{infos_changeset: infos_changeset, email_changeset: email_changeset, password_changeset: password_changeset} =
      Keyword.merge(defaults, options) |> Enum.into(%{})

    conn
    |> render("show.html",
      user: user,
      infos_changeset: infos_changeset,
      email_changeset: email_changeset,
      password_changeset: password_changeset
    )
  end
end
