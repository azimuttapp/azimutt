defmodule Azimutt do
  @moduledoc """
  Azimutt keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias Azimutt.Utils.Stringx

  def config([main_key | rest] = keyspace) when is_list(keyspace) do
    main = Application.fetch_env!(:azimutt, main_key)

    Enum.reduce(rest, main, fn next_key, current ->
      case Keyword.fetch(current, next_key) do
        {:ok, val} -> val
        :error -> raise ArgumentError, "no config found under #{Stringx.inspect(keyspace)}"
      end
    end)
  end

  def config(key, default \\ nil) when is_atom(key) do
    Application.get_env(:azimutt, key, default)
  end

  def plans do
    # Next ones: Explore ($3), Expand ($13), Extend ($25)
    [
      %{
        id: :free,
        name: "Explorer",
        description: "Design or Explore any kind of database, seamlessly.",
        monthly: 0,
        annually: 0,
        features: [
          "Database design with AML",
          "Database exploration",
          "Unlimited Projects",
          "Unlimited Tables",
          "Up to 3 layouts per project"
        ],
        buy: "/login?plan=free",
        selected: false
      },
      %{
        id: :pro,
        name: "Pro",
        description: "Remove limits, make Azimutt a central space for collaboration.",
        monthly: 13,
        annually: 130,
        features: [
          "Everything included in Explorer",
          "Unlimited Notes & Memos",
          "Unlimited Layouts",
          "Layout customization",
          "Database access",
          "Extended schema analysis",
          "Premium support"
        ],
        buy: "/login?plan=pro",
        selected: true
      },
      %{
        id: :enterprise,
        name: "Enterprise",
        description: "Features you only dreamed of to ease database understanding and management.",
        monthly: nil,
        annually: nil,
        features: [
          "Everything included in Pro",
          "User roles",
          "Schema change alerting",
          "Advanced data access",
          "AI query generation"
        ],
        buy: "mailto:#{Azimutt.config(:support_email)}",
        selected: false
      }
    ]
  end

  def use_cases do
    [
      %{
        id: "design",
        # adjustments-horizontal / sparkles
        icon: "academic-cap",
        name: "Design",
        description: "Make beautiful diagrams at your typing speed using our minimal DSL."
      },
      %{
        id: "explore",
        # cursor-arrow-ripple / document-magnifying-glass / eye / globe-europe-africa / magnifying-glass-circle / map / rectangle-group
        icon: "cursor-arrow-rays",
        name: "Explore",
        description: "The all-in-one tool to understand your database following your thought process."
      },
      %{
        id: "document",
        # tag / archive-box / bars-3-center-left
        icon: "book-open",
        name: "Document",
        description: "Nice and contextual documentation for databases is now finally a reality."
      },
      %{
        id: "analyze",
        # check-badge / beaker / clipboard-document-check / finger-print / funnel
        icon: "shield-check",
        name: "Analyze",
        description: "Identify database design warts and automate any check to keep it consistent."
      }
    ]
  end

  def features do
    [
      %{
        id: "erd",
        icon: "rectangle-stack",
        name: "An ERD that scales",
        description: "Avoid unreadable diagram, choose what's displayed: tables, columns, relations, order...",
        image: "/images/screenshots/see-what-you-need.png"
      },
      %{
        id: "aml",
        icon: "code-bracket",
        name: "Design fast with AML",
        description: "Minimal, intuitive & permissive DSL to design your database at your typing speed.",
        image: "/images/screenshots/aml.png"
      },
      %{
        id: "notes",
        icon: "document-text",
        name: "Document and showcase",
        description: "Table and column notes for documentations, layout memos visual indications.",
        image: "/images/screenshots/memos.png"
      },
      %{
        id: "analysis",
        icon: "shield-check",
        name: "A linter for your database",
        description: "Azimutt analysis will point you inconsistencies and possible improvements in your schema.",
        image: "/images/screenshots/analysis.png"
      },
      %{
        id: "compatibility",
        icon: "circle-stack",
        name: "Works with any database",
        description: "Relational and Document ones natively, but easily extended through JSON.",
        image: "/images/screenshots/nested-columns.png"
      },
      %{
        id: "sharing",
        icon: "presentation-chart-bar",
        name: "Show to the world",
        description: "Embed your diagram wherever you want, secretly share with anyone.",
        image: "/images/screenshots/private-link.png"
      },
      %{
        id: "find-path",
        icon: "map",
        name: "Path between tables",
        description: "When you don't know the path, Azimutt will. Choose the right one.",
        image: "/images/screenshots/find-path.png"
      },
      %{
        id: "relations",
        icon: "arrows-right-left",
        name: "Explore following relations",
        description: "Find your starting point, then navigate from it: in and out relations.",
        image: "/images/screenshots/follow-your-mind.png"
      },
      %{
        id: "collaboration",
        icon: "user-group",
        name: "Collaborate with your peers",
        description: "Solo investigation is cool, but sharing findings with others is even better.",
        image: "/images/illustrations/team-collaboration.jpg"
      },
      %{
        id: "data-explorer",
        icon: "archive-box",
        name: "Data access on demand",
        description: "When the schema is not enough, go deeper, digging in real data.",
        image: "/images/screenshots/data-sample-table.png"
      },
      %{
        id: "scriptable",
        icon: "command-line",
        name: "Made for developers",
        description: "Scriptable tools unleash tremendous power. You have no limit.",
        image: "/images/screenshots/js-console.png"
      },
      %{
        id: "support",
        icon: "sparkles",
        name: "Best in class support",
        description: "We're eager to help you succeed, reach out for a friendly help.",
        image: "/images/illustrations/team-support.jpg"
      }
      # %{
      #   id: "search",
      #   icon: "magnifying-glass-circle",
      #   name: "A powerful search",
      #   description: "When you don't know, it will. Fuzzy search in names, comments and more.",
      #   image: "/images/screenshots/???.png"
      # },
      # %{
      #   id: "layouts",
      #   icon: "book-open",
      #   name: "Save your findings",
      #   description: "A great schema is worth 1000 words. Keep them for later use with layouts.",
      #   image: "/images/screenshots/layouts.png"
      # },
      # %{
      #   id: "colors",
      #   icon: "paint-brush",
      #   name: "Colors mean a lot",
      #   description: "Use colors to convey meaning, make your diagram cristal clear.",
      #   image: "/images/screenshots/???.png"
      # },
      # %{
      #   id: "multi-sources",
      #   icon: "arrows-pointing-in",
      #   name: "Gather all your databases",
      #   description: "Ideal for micro-services, CQRS, or drafting new features.",
      #   image: "/images/screenshots/sources.png"
      # },
    ]
  end
end
