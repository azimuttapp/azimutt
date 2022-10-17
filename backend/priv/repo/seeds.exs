alias Azimutt.Accounts.User
alias Azimutt.Organizations.Organization
alias Azimutt.Organizations.OrganizationMember
alias Azimutt.Organizations.OrganizationInvitation
alias Azimutt.Projects.Project
alias Azimutt.Projects.Project.Storage

Azimutt.Repo.delete_all(Project)
Azimutt.Repo.delete_all(OrganizationInvitation)
Azimutt.Repo.delete_all(OrganizationMember)
Azimutt.Repo.delete_all(Organization)
Azimutt.Repo.delete_all(User)

now = DateTime.utc_now()

user_admin_attrs = %User{
  slug: "admin",
  name: "Admin Admin",
  email: "admin@example.com",
  avatar: Faker.Avatar.image_url(),
  company: "Azimutt",
  location: "Paris",
  description: "Admin account for Azimutt",
  github_username: "azimuttapp",
  twitter_username: "azimuttapp",
  is_admin: true,
  hashed_password: "$2b$12$MjhB/IpjXMy/kkXGA2EchOo/W9gjeORa4CQ7Odw3cRdTzdXtjLlWW",
  last_signin: now,
  confirmed_at: now
}

user_admin = Azimutt.Repo.insert!(user_admin_attrs)
{:ok, _user_org} = Azimutt.Organizations.create_personal_organization(user_admin)

azimutt_org_attrs = %{
  name: "Azimutt",
  contact_email: user_admin.email,
  logo: Faker.Avatar.image_url(),
  location: "Paris",
  description: "Azimutt's organization.",
  github_username: "azimuttapp",
  twitter_username: "azimuttapp"
}

{:ok, azimutt_org} = Azimutt.Organizations.create_non_personal_organization(azimutt_org_attrs, user_admin)

for i <- 1..5 do
  Azimutt.Projects.create_project(
    %{
      name: Faker.App.name() <> Integer.to_string(i),
      description: Faker.Lorem.sentence(14, "..."),
      storage_kind: Storage.local(),
      encoding_version: 2,
      nb_sources: Enum.random(1..6),
      nb_tables: Enum.random(50..1800),
      nb_columns: Enum.random(30..9999),
      nb_relations: Enum.random(9..300),
      nb_types: Enum.random(0..30),
      nb_comments: Enum.random(10..500),
      nb_notes: Enum.random(0..100),
      nb_layouts: Enum.random(1..20)
    },
    azimutt_org,
    user_admin
  )
end

# for i <- 1..10 do
#  user = %{
#    name: Faker.Person.name() <> Integer.to_string(i),
#    email: Faker.Internet.email(),
#    password: "passpasspass",
#    avatar: Faker.Avatar.image_url(),
#    company: Faker.Company.En.name(),
#    location: Faker.Address.En.country(),
#    description: Faker.Lorem.paragraph(),
#    github_username: Faker.Internet.user_name(),
#    twitter_username: Faker.Internet.user_name()
#  }
#
#  Azimutt.Accounts.register_password_user(user, now)
# end
#
## Non personal Organizations
# for i <- 1..3 do
#  organization = %{
#    name: Faker.Company.name() <> Integer.to_string(i),
#    contact_email: user_admin.email,
#    logo: Faker.Avatar.image_url(),
#    location: Faker.Address.En.country(),
#    description: Faker.Lorem.sentence(14, "...")
#  }
#
#  Azimutt.Organizations.create_non_personal_organization(organization, user_admin)
# end
