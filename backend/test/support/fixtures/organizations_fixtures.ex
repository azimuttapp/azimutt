defmodule Azimutt.OrganizationsFixtures do
  @moduledoc false

  def organization_fixture(user, attrs \\ %{}) do
    {:ok, organization} =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description",
        logo: Faker.Avatar.image_url(),
        stripe_customer_id: "cus_xxx",
        is_archived: false,
        is_private: true,
        is_personal: false
      })
      |> Azimutt.Organizations.create_non_personal_organization(user)

    organization
    |> Azimutt.Repo.preload(:projects)
    |> Azimutt.Repo.preload(:members)
    |> Azimutt.Repo.preload(:invitations)
  end

  def organization_invitation_fixture(organization, user, attrs \\ %{}) do
    {:ok, organization_invitation} =
      attrs
      |> Enum.into(%{
        sent_to: "inviteduser#{System.unique_integer()}@example.com"
      })
      |> Azimutt.Organizations.create_organization_invitation("url", organization.id, user, DateTime.utc_now())

    organization_invitation
  end
end
