defmodule AzimuttWeb.UserSessionControllerTest do
  use AzimuttWeb.ConnCase, async: true

  import Azimutt.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "DELETE /users/log_out" do
    @tag :skip
    test "logs the user out", %{conn: conn, user: user} do
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
