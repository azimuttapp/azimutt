alias Azimutt.Accounts.User
alias Azimutt.Heroku
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

admin_attrs = %User{
  slug: "admin",
  name: "Azimutt Admin",
  email: "admin@azimutt.app",
  avatar: Faker.Avatar.image_url(),
  github_username: "azimuttapp",
  twitter_username: "azimuttapp",
  is_admin: true,
  hashed_password: "$2b$12$MjhB/IpjXMy/kkXGA2EchOo/W9gjeORa4CQ7Odw3cRdTzdXtjLlWW",
  last_signin: now,
  confirmed_at: now
}

admin = Azimutt.Repo.insert!(admin_attrs)
{:ok, _admin_org} = Azimutt.Organizations.create_personal_organization(admin)

azimutt_org_attrs = %{
  name: "Azimutt",
  contact_email: "hey@azimutt.app",
  logo: Faker.Avatar.image_url(),
  location: "Paris",
  description: "Azimutt's organization.",
  github_username: "azimuttapp",
  twitter_username: "azimuttapp"
}

{:ok, azimutt_org} = Azimutt.Organizations.create_non_personal_organization(azimutt_org_attrs, admin)

{:ok, basic_project_file} = File.read("priv/static/elm/samples/basic.azimutt.json")
IO.inspect(basic_project_file, label: "basic_project_file")

{:ok, basic_project} =
  Azimutt.Projects.create_project(
    %{
      name: "Basic",
      description: nil,
      storage_kind: Storage.remote(),
      encoding_version: 2,
      file: basic_project_file,
      nb_sources: 1,
      nb_tables: 4,
      nb_columns: 19,
      nb_relations: 3,
      nb_types: 0,
      nb_comments: 2,
      nb_layouts: 1,
      nb_notes: 0,
      nb_memos: 0
    },
    azimutt_org,
    admin
  )

{:ok, _basic_sample} =
  %Azimutt.Gallery.Sample{
    project: basic_project,
    slug: "basic",
    icon: "academic-cap",
    color: "pink",
    website: "https://azimutt.app",
    banner: "/gallery/basic.png",
    tips: "Simple login/role schema. The easiest one, just enough play with Azimutt features.",
    description:
      "A very simple schema, with only 4 tables to start playing with all the Azimutt features. It's not much but it's enough. Don't lose time understanding all the subtleties of a specific database just to experiment this new shinny Entity Relationship Diagram tool.",
    analysis: """
    This database schema is not the most innovative one. But still, it's rich enough to experiment many [powerful features](/blog/how-to-explore-your-database-schema-with-azimutt) of Azimutt that make it a very special Entity Relationship Diagram targeted at real world databases.

    First, you see all the tables but with big database schema this is not convenient. Use right click (or even keyboard shortcut!) to **hide tables and columns at will**. This makes exploration of huge databases possible, and even pleasant.

    Columns with relations to hidden tables have a colored icon. Click on it to **follow the relation**! That's the best way to navigate in your schema.

    If you are still lost and don't know which path to take to join two tables, try the **find path** feature (table menu or top right lightning). It will do all the hard work for you, following every path to find the right relations.

    Once you are happy with your diagram, **save it as a layout**. So you can come back to it later. Layouts are useful to keep diagrams for features, team scopes or even onboarding new developers.

    While we are at it, let's talk about documentation. It can be a good idea to put it on **SQL comments** as a single source of truth. Azimutt will show them with a small bubble on tables and columns. But sometimes it's more convenient to update them directly in the diagram. That's why Azimutt has **notes** that you can put on tables and columns as well (try right click on them).

    Now you have the basics to use Azimutt. But keep exploring it as there is so much more to discover 😉

    Azimutt is very active with new features every month. We prioritize a lot from users feedback. So if something bother you or if you see any possible improvement, please [don't hesitate to reach out]({{issues_link}})! It can be a small typo or one UX tweak, but also big features like desktop app, live database access or CI integration. This will help you, us, and all the other Azimutt users!
    """
  }
  |> Azimutt.Repo.insert()

{:ok, _public_basic_project} =
  basic_project
  |> Ecto.Changeset.cast(%{visibility: :read}, [:visibility])
  |> Azimutt.Repo.update()

{:ok, _heroku} =
  Heroku.create_resource(%{
    id: "8d97f847-ef86-489a-bfdb-b8d83d5c0926",
    name: "heroku-app",
    plan: "free",
    region: "eu",
    options: nil,
    callback: "https://api.heroku.com/addons/01234567-89ab-cdef-0123-456789abcdef",
    oauth_code: "2365b1f8-9111-4e64-b7ae-43ed192ce1bd",
    oauth_type: "amazon-web-services::us-east-1",
    oauth_expire: "2023-03-03T18:01:31-0800"
  })
