# Why have this in `azimutt_web/controllers`???
defmodule AzimuttWeb.UserAuth do
  @moduledoc "base auth module generate by `mix phx.gen.auth`"
  import Plug.Conn
  import Phoenix.Controller
  alias Azimutt.Accounts
  alias Azimutt.Heroku
  alias Azimutt.Heroku.Resource
  alias Azimutt.Tracking
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

  @attribution_cookie "_azimutt_attribution"
  @attribution_options [sign: true, max_age: 30 * @days, same_site: "Lax"]

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
  def login_user_and_redirect(conn, user, method, params \\ %{}) do
    conn
    |> login_user(user, method, params)
    |> redirect_after_login()
  end

  def login_user(conn, user, method, params \\ %{}) do
    Tracking.user_login(user, method)
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> put_session(:user_return_to, user_return_to)
    |> delete_resp_cookie(@attribution_cookie)
    |> maybe_write_remember_me_cookie(token, params)
  end

  def redirect_after_login(conn) do
    conn |> redirect(to: get_session(conn, :user_return_to) || Routes.user_dashboard_path(conn, :index))
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
    |> delete_resp_cookie(@heroku_cookie)
    |> delete_resp_cookie(@attribution_cookie)
    |> redirect(to: Routes.website_path(conn, :index))
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    user = user |> Azimutt.Repo.preload(:profile) |> Azimutt.Repo.preload(organizations: [:heroku_resource, :projects])
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

  def redirect_if_user_is_authed(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: Routes.user_dashboard_path(conn, :index))
      |> halt()
    else
      conn
    end
  end

  def require_authed_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn |> enforce_user_requirements(%{})
    else
      conn
      |> maybe_store_return_to()
      |> put_flash(:info, "Please login before accessing the required page.")
      |> redirect(to: Routes.user_session_path(conn, :new))
      |> halt()
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def enforce_user_requirements(conn, _opts) do
    user = conn.assigns[:current_user]
    path = conn.request_path

    cond do
      !user ->
        conn

      !user.confirmed_at && Azimutt.config(:require_email_confirmation) && !Azimutt.config(:skip_email_confirmation) &&
        !is_email_confirm_path(conn, path) && Date.compare(user.created_at, ~D[2023-04-19]) == :gt ->
        conn |> redirect(to: Routes.user_confirmation_path(conn, :new)) |> halt()

      user.onboarding && !Azimutt.config(:skip_onboarding_funnel) &&
        !is_onboarding_path(conn, path) && !is_email_confirm_path(conn, path) ->
        conn |> redirect(to: Routes.user_onboarding_path(conn, user.onboarding |> String.to_atom())) |> halt()

      true ->
        conn
    end
  end

  defp is_email_confirm_path(conn, path), do: path |> String.starts_with?(Routes.user_confirmation_path(conn, :new))
  defp is_onboarding_path(conn, path), do: path |> String.starts_with?(Routes.user_onboarding_path(conn, :index))

  def require_authed_user_api(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn |> put_error_api(:unauthorized, "User not authenticated, go to azimutt.app to login")
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
            conn |> put_error_api(:unauthorized, "Invalid credentials for heroku basic auth")
          end

        :error ->
          conn |> put_error_api(:unauthorized, "Invalid or missing heroku basic auth")
      end
    else
      conn |> put_error_api(:unauthorized, "Heroku basic auth not set up")
    end
  end

  # write @heroku_cookie to make the specified resource accessible
  def heroku_sso(conn, resource, user) do
    conn
    |> login_user(user, "heroku")
    |> put_resp_cookie(@heroku_cookie, %{resource_id: resource.id}, @heroku_options)
  end

  # read @heroku_cookie and make resource available in conn
  def fetch_heroku_resource(conn, _opts) do
    conn = fetch_cookies(conn, signed: [@heroku_cookie])

    with(
      {:ok, cookie} <- Result.from_nillable(conn.cookies[@heroku_cookie]),
      {:ok, %Resource{} = resource} <- Heroku.get_resource(cookie.resource_id),
      do: {:ok, conn |> assign(:heroku, resource)}
    )
    |> Result.or_else(conn)
  end

  def require_heroku_resource(conn, _opts) do
    if conn.assigns[:heroku] do
      conn
    else
      conn |> put_error_html(:forbidden, "403.html", "Please access this resource through heroku add-on SSO.")
    end
  end

  def require_heroku_resource_api(conn, _opts) do
    if conn.assigns[:heroku] do
      conn
    else
      conn |> put_error_api(:unauthorized, "Not accessible heroku resource, access it from heroku dashboard.")
    end
  end

  def require_admin_user(conn, _opts) do
    if conn.assigns[:current_user] && conn.assigns[:current_user].is_admin do
      conn
    else
      # TODO: can I render FallbackController {:error, :forbidden}?
      conn |> put_error_html(:forbidden, "403.html", "This section is for admins only.")
    end
  end

  def track_attribution(conn, _opts) do
    params =
      ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "ref", "via"]
      |> Enum.reduce(%{}, fn attr, acc ->
        value = conn.params[attr]
        if value != nil && value != "", do: acc |> Map.put(attr, value), else: acc
      end)

    referer = conn |> get_req_header("referer") |> Enum.filter(fn h -> !String.contains?(h, Azimutt.config(:host)) end) |> List.first()
    headers = if referer != nil, do: %{"referer" => referer}, else: %{}
    attributes = params |> Map.merge(headers)

    if attributes |> map_size() > 0 do
      details = attributes |> Map.put("path", conn.request_path)
      event = Tracking.attribution(conn.assigns.current_user, details)

      if conn.assigns.current_user == nil do
        cookie =
          details
          |> Map.put("date", DateTime.utc_now())
          |> Map.put("event", event |> Result.map(fn e -> e.id end) |> Result.or_else(nil))

        conn |> put_resp_cookie(@attribution_cookie, cookie, @attribution_options)
      else
        conn
      end
    else
      conn
    end
  end

  def get_attribution(conn) do
    conn = fetch_cookies(conn, signed: [@attribution_cookie])
    value = conn.cookies[@attribution_cookie]
    # legacy: attribution stored a list before, get the first item in this case
    if(is_list(value), do: hd(value), else: value)
  end

  defp put_error_html(conn, status, view, message) do
    conn
    |> put_status(status)
    |> put_view(AzimuttWeb.ErrorView)
    |> put_layout({AzimuttWeb.LayoutView, "empty.html"})
    |> put_root_layout({AzimuttWeb.LayoutView, "root_hfull.html"})
    |> render(view, message: message)
    |> halt()
  end

  defp put_error_api(conn, status, message) do
    conn
    |> put_status(status)
    |> put_view(AzimuttWeb.ErrorView)
    |> render("error.json", message: message)
    |> halt()
  end

  defp maybe_store_return_to(%{method: "GET"} = conn), do: conn |> put_session(:user_return_to, current_path(conn))
  defp maybe_store_return_to(conn), do: conn
end
