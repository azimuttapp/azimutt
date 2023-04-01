defmodule AzimuttWeb.UserSessionControllerTest do
  use AzimuttWeb.ConnCase, async: true
  import Azimutt.AccountsFixtures

  setup do
    Application.put_env(:azimutt, :auth_password, true)
    Application.put_env(:azimutt, :auth_github, true)

    on_exit(fn ->
      Application.delete_env(:azimutt, :auth_password)
      Application.delete_env(:azimutt, :auth_github)
    end)
  end

  test "GET /login", %{conn: conn} do
    conn = get(conn, Routes.user_session_path(conn, :new))
    assert html_response(conn, 200) =~ "Forgot your password?"
  end

  describe "DELETE /logout" do
    @tag :skip
    test "logs the user out", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
    end

    @tag :skip
    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
    end
  end
end
