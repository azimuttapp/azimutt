# handle specific Heroku needs for https://elements.heroku.com/addons#data-store-utilities
# see https://devcenter.heroku.com/categories/building-add-ons
# see https://devcenter.heroku.com/articles/building-an-add-on
# see https://devcenter.heroku.com/articles/add-on-single-sign-on
defmodule AzimuttWeb.HerokuController do
  use AzimuttWeb, :controller
  alias Azimutt.Heroku
  alias Azimutt.Heroku.Resource
  alias Azimutt.Utils.Crypto
  alias Azimutt.Utils.Result
  alias AzimuttWeb.UserAuth
  action_fallback AzimuttWeb.FallbackController

  # https://devcenter.heroku.com/articles/add-on-single-sign-on
  # https://devcenter.heroku.com/articles/building-an-add-on#the-provisioning-request-example-request
  def login(conn, %{"resource_id" => heroku_id, "timestamp" => timestamp, "resource_token" => token} = params) do
    # credo:disable-for-next-line
    IO.inspect(params, label: "Heroku login")
    now = System.os_time(:second)
    user = %{app: params["app"], email: params["email"]}
    salt = Application.get_env(:heroku, :sso_salt)
    older_than_5_min = String.to_integer(timestamp) < now - 5 * 60
    expected_token = Crypto.sha1("#{heroku_id}:#{salt}:#{timestamp}")
    invalid_token = !Plug.Crypto.secure_compare(expected_token, token)

    if older_than_5_min || invalid_token do
      {:error, :forbidden}
    else
      with {:ok, %Resource{} = resource} <- Heroku.get_resource(heroku_id) |> Result.filter_not(fn r -> r.deleted_at end, :gone),
           do: conn |> UserAuth.heroku_sso(resource, user)
    end
  end

  def show(conn, %{"heroku_id" => heroku_id} = params) do
    # credo:disable-for-next-line
    IO.inspect(params, label: "Heroku show resource")
    resource = conn.assigns.heroku_resource
    user = conn.assigns.heroku_user

    if resource.heroku_id == heroku_id do
      conn |> render("show.html", resource: resource, user: user)
    else
      {:error, :forbidden}
    end
  end

  # defp heroku_dashboard(user), do: "https://dashboard.heroku.com/apps/#{user.app}"
end
