defmodule AzimuttWeb.UserRegistrationController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Accounts.User
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  def new(conn, %{"user" => user_params}) do
    now = DateTime.utc_now()
    changeset = Accounts.change_user_registration(user_params, %User{}, now)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    now = DateTime.utc_now()

    case Accounts.register_password_user(user_params, now) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
