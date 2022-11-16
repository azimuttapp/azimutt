defmodule Azimutt.OrganizationsTest do
  use Azimutt.DataCase
  import Azimutt.AccountsFixtures
  alias Azimutt.Organizations

  describe "organizations" do
    alias Azimutt.Organizations.Organization
    import Azimutt.AccountsFixtures
    import Azimutt.OrganizationsFixtures

    @invalid_attrs %{name: nil}

    setup do
      %{user: user_fixture()}
    end

    @tag :skip
    test "list_organizations/0 returns all organizations" do
      user = user_fixture()
      organization = organization_fixture(user)
      assert Organizations.list_organizations() == [organization]
    end

    @tag :skip
    test "get_organization/1 returns the organization with given id" do
      user = user_fixture()
      organization = organization_fixture(user)
      assert {:ok, organization} == Organizations.get_organization(organization.id)
    end

    @tag :skip
    test "create_organization/1 with valid data creates a organization", %{user: user} do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Organization{} = organization} = Organizations.create_organization(valid_attrs, user)

      assert organization.name == "some name"
    end

    @tag :skip
    test "create_organization/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Organizations.create_organization(@invalid_attrs, user)
    end

    @tag :skip
    test "update_organization/2 with valid data updates the organization" do
      user = user_fixture()
      organization = organization_fixture(user)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Organization{} = organization} = Organizations.update_organization(organization, update_attrs)

      assert organization.name == "some updated name"
    end

    @tag :skip
    test "update_organization/2 with invalid data returns error changeset" do
      user = user_fixture()
      organization = organization_fixture(user)

      assert {:error, %Ecto.Changeset{}} = Organizations.update_organization(organization, @invalid_attrs)

      assert {:ok, organization} == Organizations.get_organization(organization.id)
    end

    @tag :skip
    test "delete_organization/1 deletes the organization" do
      user = user_fixture()
      organization = organization_fixture(user)
      assert {:ok, %Organization{}} = Organizations.delete_organization(organization)
      assert {:error, :not_found} == Organizations.get_organization(organization.id)
    end

    @tag :skip
    test "change_organization/1 returns a organization changeset" do
      user = user_fixture()
      organization = organization_fixture(user)
      assert %Ecto.Changeset{} = Organizations.change_organization(organization)
    end
  end

  describe "organization_invitations" do
    alias Azimutt.Organizations.OrganizationInvitation

    import Azimutt.OrganizationsFixtures

    @invalid_attrs %{sent_to: nil, token: nil}

    @tag :skip
    test "get_organization_invitation/1 returns the organization_invitation with given id" do
      user = user_fixture()
      organization = organization_fixture(user)
      organization_invitation = organization_invitation_fixture(organization, user)

      assert {:ok, organization_invitation} == Organizations.get_organization_invitation(organization_invitation.id)
    end

    @tag :skip
    test "create_organization_invitation/1 with valid data creates a organization_invitation" do
      user = user_fixture()
      organization = organization_fixture(user)

      valid_attrs = %{
        organization_id: organization.id,
        sent_to: "some sent_to"
      }

      assert {:ok, %OrganizationInvitation{} = organization_invitation} = Organizations.create_organization_invitation(valid_attrs, "url")

      assert organization_invitation.sent_to == "some sent_to"
    end

    @tag :skip
    test "create_organization_invitation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organizations.create_organization_invitation(@invalid_attrs, "url")
    end

    @tag :skip
    test "change_organization_invitation/1 returns a organization_invitation changeset" do
      user = user_fixture()
      organization = organization_fixture(user)
      organization_invitation = organization_invitation_fixture(organization, user)

      assert %Ecto.Changeset{} = Organizations.change_organization_invitation(organization_invitation)
    end
  end
end
