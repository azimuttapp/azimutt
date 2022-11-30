defmodule Azimutt.GalleryFixtures do
  @moduledoc false
  alias Azimutt.Projects.Project

  def sample_fixture(%Project{} = project, attrs \\ %{}) do
    required = [:slug, :icon, :color, :website, :banner, :tips, :description, :analysis]

    default = %{
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

    {:ok, public_project} =
      project
      |> Ecto.Changeset.cast(%{visibility: :read}, [:visibility])
      |> Azimutt.Repo.update()

    {:ok, sample} =
      %Azimutt.Gallery.Sample{}
      |> Ecto.Changeset.cast(attrs |> Enum.into(default), required)
      |> Ecto.Changeset.put_change(:project, public_project)
      |> Ecto.Changeset.validate_required(required)
      |> Azimutt.Repo.insert()

    sample
  end
end
