defmodule Azimutt.OrganizationsTest do
  use Azimutt.DataCase
  import Azimutt.AccountsFixtures
  alias Azimutt.Organizations

  describe "organizations" do
    alias Azimutt.Organizations.Organization
    import Azimutt.AccountsFixtures
    import Azimutt.OrganizationsFixtures

    setup do
      %{user: user_fixture()}
    end

    @tag :skip
    test "list_organizations/0 returns all organizations" do
      user = user_fixture()
      organization = organization_fixture(user)
      assert Organizations.list_organizations(user) == [organization]
    end

    @tag :skip
    test "get_organization/1 returns the organization with given id" do
      user = user_fixture()
      organization = organization_fixture(user)
      assert {:ok, organization} == Organizations.get_organization(organization.id, user)
    end

    @tag :skip
    test "create_personal_organization/1 with valid data creates a organization", %{user: user} do
      assert {:ok, %Organization{} = organization} = Organizations.create_personal_organization(user)
      assert organization.name == "some name"
    end

    @tag :skip
    test "create_non_personal_organization/1 with valid data creates a organization", %{user: user} do
      valid_attrs = %{name: "Orga name", logo: Faker.Avatar.image_url()}
      assert {:ok, %Organization{} = organization} = Organizations.create_non_personal_organization(valid_attrs, user)
      assert organization.name == "some name"
    end

    @tag :skip
    test "update_organization/2 with valid data updates the organization" do
      user = user_fixture()
      organization = organization_fixture(user)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Organization{} = organization} = Organizations.update_organization(update_attrs, organization, user)

      assert organization.name == "some updated name"
    end

    @tag :skip
    test "update_organization/2 with invalid data returns error changeset" do
      user = user_fixture()
      organization = organization_fixture(user)

      assert {:error, %Ecto.Changeset{}} = Organizations.update_organization(%{name: nil}, organization, user)

      assert {:ok, organization} == Organizations.get_organization(organization.id, user)
    end

    @tag :skip
    test "delete_organization/1 deletes the organization" do
      now = DateTime.utc_now()
      user = user_fixture()
      organization = organization_fixture(user)
      assert {:ok, %Organization{}} = Organizations.delete_organization(organization, now)
      assert {:error, :not_found} == Organizations.get_organization(organization.id, user)
    end
  end

  describe "organization_invitations" do
    alias Azimutt.Organizations.OrganizationInvitation
    import Azimutt.OrganizationsFixtures

    @tag :skip
    test "get_organization_invitation/1 returns the organization_invitation with given id" do
      user = user_fixture()
      organization = organization_fixture(user)
      organization_invitation = organization_invitation_fixture(organization, user)

      assert {:ok, organization_invitation} == Organizations.get_organization_invitation(organization_invitation.id)
    end

    @tag :skip
    test "create_organization_invitation/1 with valid data creates a organization_invitation" do
      now = DateTime.utc_now()
      user = user_fixture()
      organization = organization_fixture(user)
      valid_attrs = %{sent_to: "hey@mail.com"}

      assert {:ok, %OrganizationInvitation{} = organization_invitation} = Organizations.create_organization_invitation(valid_attrs, "url", organization.id, user, now)
      assert organization_invitation.sent_to == "some sent_to"
    end

    @tag :skip
    test "create_organization_invitation/1 with invalid data returns error changeset" do
      now = DateTime.utc_now()
      user = user_fixture()
      organization = organization_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Organizations.create_organization_invitation(%{sent_to: nil}, "url", organization.id, user, now)
    end
  end
end
