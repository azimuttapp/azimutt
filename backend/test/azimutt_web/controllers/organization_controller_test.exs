defmodule AzimuttWeb.OrganizationControllerTest do
  use AzimuttWeb.ConnCase, async: true
  import Azimutt.AccountsFixtures
  import Azimutt.OrganizationsFixtures
  setup :register_and_log_in_user

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  describe "new organization" do
    @tag :skip
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.organization_path(conn, :new))
      assert html_response(conn, 200) =~ "Create your organization"
    end
  end

  describe "create organization" do
    @tag :skip
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.organization_path(conn, :create), organization: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.organization_path(conn, :show, id)

      conn = get(conn, Routes.organization_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Organization"
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.organization_path(conn, :create), organization: @invalid_attrs)
      assert html_response(conn, 200) =~ "Create your organization"
    end
  end

  describe "edit organization" do
    setup [:create_organization]

    @tag :skip
    test "renders form for editing chosen organization", %{conn: conn, organization: organization} do
      conn = get(conn, Routes.organization_path(conn, :edit, organization))
      assert html_response(conn, 200) =~ "Settings"
    end
  end

  describe "update organization" do
    setup [:create_organization]

    @tag :skip
    test "redirects when data is valid", %{conn: conn, organization: organization} do
      conn = put(conn, Routes.organization_path(conn, :update, organization), organization: @update_attrs)

      assert redirected_to(conn) == Routes.organization_path(conn, :show, organization)

      conn = get(conn, Routes.organization_path(conn, :show, organization))
      assert html_response(conn, 200) =~ "some updated name"
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn, organization: organization} do
      conn = put(conn, Routes.organization_path(conn, :update, organization), organization: @invalid_attrs)

      assert html_response(conn, 200) =~ "Settings"
    end
  end

  describe "delete organization" do
    setup [:create_organization]

    @tag :skip
    test "deletes chosen organization", %{conn: conn, organization: organization} do
      conn = delete(conn, Routes.organization_path(conn, :delete, organization))
      assert redirected_to(conn) == Routes.organization_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.organization_path(conn, :show, organization))
      end
    end
  end

  defp create_organization(_) do
    user = user_fixture()
    organization = organization_fixture(user)
    %{organization: organization}
  end
end
