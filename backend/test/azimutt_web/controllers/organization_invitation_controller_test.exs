defmodule AzimuttWeb.OrganizationInvitationControllerTest do
  use AzimuttWeb.ConnCase, async: true
  import Azimutt.AccountsFixtures
  import Azimutt.OrganizationsFixtures
  setup :register_and_log_in_user

  @create_attrs %{sent_to: "some sent_to"}
  @invalid_attrs %{sent_to: nil, token: nil}

  setup do
    user = user_fixture()
    %{organization: organization_fixture(user)}
  end

  describe "index" do
    @tag :skip
    test "lists all organization_invitations", %{conn: conn, organization: organization} do
      conn = get(conn, Routes.organization_member_path(conn, :index, organization.id))
      assert html_response(conn, 200) =~ "Add team members"
    end
  end

  describe "create organization_invitation" do
    @tag :skip
    test "redirects to show when data is valid", %{conn: conn, organization: organization} do
      invitation_attrs = @create_attrs |> Map.put(:organization_id, organization.id)

      conn = post(conn, Routes.organization_member_path(conn, :create_invitation, organization.id), organization_invitation: invitation_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.invitation_path(conn, :show, id)

      conn = get(conn, Routes.invitation_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Organization invitation created successfully."
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn, organization: organization} do
      conn = post(conn, Routes.organization_member_path(conn, :create_invitation, organization.id), organization_invitation: @invalid_attrs)

      assert html_response(conn, 200) =~ "Add team members"
    end
  end
end
