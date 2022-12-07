defmodule AzimuttWeb.UserAuth do
  @moduledoc "base auth module generate by `mix phx.gen.auth`"
  import Plug.Conn
  import Phoenix.Controller
  alias Azimutt.Accounts
  alias Azimutt.Accounts.User
  alias Azimutt.Heroku
  alias Azimutt.Heroku.Resource
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Router.Helpers, as: Routes

  @seconds 1
  @minutes 60 * @seconds
  @hours 60 * @minutes
  @days 24 * @hours

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @remember_me_cookie "_azimutt_web_user_remember_me"
  @remember_me_options [sign: true, max_age: 60 * @days, same_site: "Lax"]

  # cf https://devcenter.heroku.com/articles/add-on-single-sign-on
  @heroku_cookie "_azimutt_heroku_sso"
  @heroku_options [sign: true, max_age: 90 * @minutes, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      AzimuttWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: Routes.website_path(conn, :index))
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    user = user |> Azimutt.Repo.preload(:organizations)
    # IO.inspect user
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> maybe_store_return_to()
      |> put_flash(:info, "Please login before accessing the required page.")
      |> redirect(to: Routes.user_session_path(conn, :new))
      |> halt()
    end
  end

  def require_authenticated_user_api(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn |> put_api_error(:unauthorized, "User not authenticated, go to azimutt.app to login")
    end
  end

  def require_heroku_basic_auth(conn, _opts) do
    heroku_addon_id = Azimutt.config(:heroku_addon_id)
    heroku_password = Azimutt.config(:heroku_password)

    if heroku_addon_id && heroku_password do
      case Plug.BasicAuth.parse_basic_auth(conn) do
        {user, pass} ->
          if Plug.Crypto.secure_compare(user, heroku_addon_id) && Plug.Crypto.secure_compare(pass, heroku_password) do
            conn
          else
            conn |> put_api_error(:unauthorized, "Invalid credentials for heroku basic auth")
          end

        :error ->
          conn |> put_api_error(:unauthorized, "Invalid or missing heroku basic auth")
      end
    else
      conn |> put_api_error(:unauthorized, "Heroku basic auth not set up")
    end
  end

  # write @heroku_cookie to make the specified resource accessible
  def heroku_sso(conn, resource, user, app) do
    conn
    |> put_resp_cookie(@heroku_cookie, %{heroku_id: resource.heroku_id, user_id: user.id, app: app}, @heroku_options)
    |> redirect(to: Routes.heroku_path(conn, :show, resource.heroku_id))
  end

  # read @heroku_cookie and make resource available in conn
  def fetch_heroku_resource(conn, _opts) do
    conn = fetch_cookies(conn, signed: [@heroku_cookie])

    with(
      {:ok, cookie} <- Result.from_nillable(conn.cookies[@heroku_cookie]),
      {:ok, %Resource{} = resource} <- Heroku.get_resource(cookie.heroku_id),
      {:ok, %User{} = user} <- Accounts.get_user(cookie.user_id),
      do: {:ok, conn |> assign(:heroku, %{resource: resource, user: user, app: cookie.app})}
    )
    |> Result.or_else(conn)
  end

  # check :heroku_resource is available or redirect
  def require_heroku_resource(conn, _opts) do
    if conn.assigns[:heroku] do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> put_view(AzimuttWeb.ErrorView)
      |> render("403.html", message: "Please access this resource through heroku add-on SSO.")
      |> halt()
    end
  end

  defp put_api_error(conn, status, message) do
    conn
    |> put_status(status)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", message: message)
    |> halt()
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"
end
