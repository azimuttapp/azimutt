defmodule AzimuttWeb.UserRegistrationController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts
  alias Azimutt.Accounts.User
  alias Azimutt.Utils.Mapx
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  def new(conn, _params) do
    now = DateTime.utc_now()
    changeset = Accounts.change_user_registration(%{}, %User{}, now)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    now = DateTime.utc_now()
    attrs = user_params |> Mapx.atomize() |> Map.put(:avatar, Faker.Avatar.image_url())

    case Accounts.register_password_user(attrs, UserAuth.get_attribution(conn), now) do
      {:ok, user} ->
        {:ok, _} = Accounts.send_email_confirmation(user, &Routes.user_confirmation_url(conn, :confirm, &1))

        conn
        |> put_flash(:info, "Azimutt account created, please check your emails to validate it and then access Azimutt.")
        |> UserAuth.login_user(user, "password")
        |> redirect(to: Routes.user_confirmation_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn |> render("new.html", changeset: changeset)
    end
  end
end
