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

  def set_config(key, value) when is_atom(key) do
    Application.put_env(:azimutt, key, value)
  end

  def plans do
    # MUST match Stripe prices defined in env vars
    %{
      free: %{
        id: :free,
        name: "Free",
        description: "Quickly explore your db with one command. No long term save.",
        monthly: "Free",
        yearly: "Free",
        features: [
          "Unlimited tables",
          "Schema exploration",
          "Data exploration"
        ],
        order: 1
      },
      solo: %{
        id: :solo,
        name: "Solo",
        description: "Personal usage with one project. Allows design and custom colors.",
        monthly: 9,
        yearly: 7,
        unit: "€ / month",
        features: [
          "Free plan features",
          "Long term usage",
          "Database design",
          "Schema export"
        ],
        order: 3
      },
      team: %{
        id: :team,
        name: "Team",
        description: "Collaborate on Azimutt with all database features.",
        monthly: 42,
        yearly: 35,
        unit: "€ / user / month",
        features: [
          "Solo plan features",
          "Database analysis",
          "Collaboration",
          "Documentation",
          "AI capabilities",
          "Export project"
        ],
        order: 4
      },
      enterprise: %{
        id: :enterprise,
        name: "Enterprise",
        description: "Getting serious: higher limits, security, control and automation.",
        monthly: "Custom",
        yearly: "Custom",
        features: [
          "Team plan features",
          "Unlimited usage",
          "User management",
          "Custom integrations"
        ],
        order: 5
      },
      pro: %{
        id: :pro,
        name: "Pro",
        monthly: 13,
        yearly: 13,
        features: [],
        order: 2
      }
    }
  end

  def active_plans, do: [plans().free, plans().solo, plans().team, plans().enterprise]

  def features do
    # MUST stay in sync with frontend/src/Models/Feature.elm
    %{
      # Database features
      schema_exploration: %{name: "Schema exploration", free: true, solo: true, team: true, enterprise: true, pro: true},
      data_exploration: %{name: "Data exploration", free: true, solo: true, team: true, enterprise: true, pro: true},
      # TODO: rename `aml` to `db_design`
      aml: %{name: "Database design", free: 10, solo: nil, team: nil, enterprise: nil, pro: nil, description: "Allowed tables in AML"},
      colors: %{name: "Custom colors", free: false, solo: true, team: true, enterprise: true, pro: true},
      # saved_queries: %{name: "Saved queries", free: false, solo: false, team: false, enterprise: true, pro: true, description: "Soon... Save and share useful queries."},
      # dashboard: %{name: "Dashboard", free: false, solo: false, team: false, enterprise: true, pro: true, description: "Soon... Visually see query results."},
      # db_stat_history: %{name: "Stats history", free: false, solo: false, team: false, enterprise: true, pro: true, description: "Soon... Keep evolutions of database stats."},
      schema_export: %{name: "Export schema", free: false, solo: true, team: true, enterprise: true, pro: true, description: "Export your schema as SQL, AML or JSON."},
      ai: %{name: "AI features", free: false, solo: false, team: true, enterprise: true, pro: true},
      analysis: %{
        name: "Database analysis",
        free: "preview",
        solo: "preview",
        team: "snapshot",
        enterprise: "trends",
        pro: "trends",
        description: "preview: top 3 suggestions, snapshot: all suggestions, trends: more suggestions based on evolution"
      },
      project_export: %{name: "Export project", free: false, solo: false, team: true, enterprise: true, pro: true},
      # Product quotas
      users: %{name: "Max users", free: 1, solo: 1, team: 5, enterprise: nil, pro: nil},
      projects: %{name: "Max projects", free: 0, solo: 3, team: 10, enterprise: nil, pro: nil, description: "0 means you can create a project but can't save it."},
      project_dbs: %{name: "Max db/project", free: 3, solo: 3, team: 10, enterprise: nil, pro: nil},
      project_layouts: %{name: "Max layout/project", free: 2, solo: 10, team: 50, enterprise: nil, pro: nil},
      layout_tables: %{name: "Max table/layout", free: 10, solo: 40, team: 100, enterprise: nil, pro: nil},
      project_doc: %{name: "Max doc/project", free: 10, solo: 100, team: 1000, enterprise: nil, pro: nil},
      # Extended integration
      project_share: %{name: "Sharing project", free: false, solo: false, team: false, enterprise: true, pro: true, description: "Use private links & embed to share with guest."},
      api: %{name: "API access", free: false, solo: false, team: false, enterprise: true, pro: true, description: "Fetch and update sources and documentation programmatically."},
      sso: %{name: "SSO", free: false, solo: false, team: false, enterprise: true, pro: false, description: "Soon..."},
      user_rights: %{name: "User rights", free: false, solo: false, team: false, enterprise: true, pro: false},
      gateway_custom: %{name: "Custom gateway", free: false, solo: false, team: false, enterprise: true, pro: false},
      billing: %{name: "Flexible billing", free: false, solo: false, team: false, enterprise: true, pro: false},
      support_on_premise: %{name: "On-premise support", free: false, solo: false, team: false, enterprise: true, pro: false},
      support_enterprise: %{name: "Enterprise support", free: false, solo: false, team: false, enterprise: true, pro: false, description: "Priority email, answer within 48h."},
      consulting: %{name: "1h expert consulting", free: false, solo: false, team: false, enterprise: true, pro: false},
      roadmap: %{name: "Roadmap impact", free: "suggestions", solo: "suggestions", team: "suggestions", enterprise: "discussions", pro: "suggestions"}
    }
  end

  # MUST stay sync with backend/lib/azimutt_web/templates/partials/_streak.html.heex
  def streak do
    [
      %{goal: 4, feature: :colors, limit: true},
      %{goal: 6, feature: :aml, limit: nil},
      %{goal: 10, feature: :ai, limit: true},
      %{goal: 15, feature: :project_layouts, limit: nil},
      %{goal: 25, feature: :schema_export, limit: true},
      %{goal: 40, feature: :analysis, limit: "trends"},
      %{goal: 60, feature: :project_share, limit: true}
    ]
  end

  def showcase_usages do
    [
      %{
        id: "explore",
        # cursor-arrow-ripple / document-magnifying-glass / eye / globe-europe-africa / magnifying-glass-circle / map / rectangle-group
        icon: "cursor-arrow-rays",
        name: "Explore",
        title: "Exploring your database",
        description: "The all-in-one tool to understand and design your database following your thought process."
      },
      %{
        id: "document",
        # tag / archive-box / bars-3-center-left
        icon: "book-open",
        name: "Document",
        title: "Documenting your database",
        description: "Nice and contextual documentation for databases is now finally a reality."
      },
      %{
        id: "analyze",
        # check-badge / beaker / clipboard-document-check / finger-print / funnel
        icon: "shield-check",
        name: "Optimize",
        title: "Analyzing your database",
        description: "Identify database design warts and automate any check to keep it consistent."
      },
      %{
        id: "design",
        # adjustments-horizontal / sparkles
        icon: "academic-cap",
        name: "Design",
        title: "Designing your database",
        description: "Make beautiful diagrams at your typing speed using our minimal DSL."
      }
    ]
  end

  def showcase_features do
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

  def connectors do
    [
      %{id: "postgres", name: "PostgreSQL", color: "#699eca", description: "The most powerful open-source relational database, known for extensibility and SQL compliance. Now explorable with Azimutt."},
      %{id: "mysql", name: "MySQL", color: "#00758f", description: "The world's most popular open-source relational database, widely used for web applications. Now accessible within Azimutt."},
      %{id: "mariadb", name: "MariaDB", color: "#444b5e", description: "An open-source fork of MySQL with improved performance, scalability, and open development. Also available to connect to Azimutt."},
      %{id: "sqlserver", name: "SQL Server", color: "#ededee", description: "A robust, enterprise-grade relational database by Microsoft, with integrated analytics and management tools. Integrated in Azimutt."},
      %{id: "oracle", name: "Oracle", color: "#e61d18", description: "A high-performance relational database widely used in enterprises for mission-critical applications. Uniquely explorable with Azimutt."},
      %{id: "mongodb", name: "MongoDB", color: "#20a854", description: "A NoSQL database designed for flexible, document-oriented storage and scalability. Collection schema and relations are inferred in Azimutt."},
      %{id: "couchbase", name: "Couchbase", color: "#ed2226", description: "A distributed NoSQL database optimized for interactive applications and real-time analytics. Infer collection schema and relations."},
      %{id: "bigquery", name: "BigQuery", color: "#4386fa", description: "Google’s fully-managed, serverless data warehouse for large-scale analytics using SQL. Discover your datasets with Azimutt."},
      %{id: "snowflake", name: "Snowflake", color: "#29b5e8", description: "A cloud-native data platform for seamless data warehousing, sharing, and analytics. Easily explorable with this Azimutt connector."}
    ]
  end

  def converters do
    [
      %{id: "aml", name: "AML", parse: true, generate: true},
      %{id: "dbml", name: "DBML", parse: true, generate: false},
      %{id: "json", name: "JSON", parse: true, generate: true},
      %{id: "postgres", name: "PostgreSQL", parse: true, generate: true},
      %{id: "mysql", name: "MySQL", parse: false, generate: false},
      %{id: "oracle", name: "Oracle", parse: false, generate: false},
      %{id: "sqlserver", name: "SQL Server", parse: false, generate: false},
      %{id: "mongodb", name: "MongoDB", parse: false, generate: false},
      %{id: "mariadb", name: "MariaDB", parse: false, generate: false},
      %{id: "prisma", name: "Prisma", parse: false, generate: false},
      %{id: "dot", name: "DOT", parse: false, generate: true},
      %{id: "mermaid", name: "Mermaid", parse: false, generate: true},
      %{id: "quicksql", name: "Quick SQL", parse: false, generate: false},
      %{id: "markdown", name: "Markdown", parse: false, generate: true},
      %{id: "amlv1", name: "AMLv1", parse: true, generate: true}
    ]
  end

  def comparisons do
    [
      %{
        id: "entity-relationship-diagram",
        name: "Entity-Relationship Diagram",
        keywords: "entity-relationship diagram,erd,database diagram,database visualization tool,database schema explorer,SQL,database",
        tools: [
          %{id: "dbdiagram", name: "dbdiagram.io", description: "An online Entity-Relationship Diagram using code to define your database schema, as fast as you can type.", pub: "2024-11-15"},
          %{id: "drawsql", name: "DrawSQL", description: "A beautiful online Entity-Relationship Diagram tool to design your database from scratch or from SQL dump.", pub: "2024-11-20"}
          # %{id: "drawdb", name: "drawDB", description: "A Free and Open Source online Entity-Relationship Diagram tool that can generate SQL."},
          # %{id: "chartdb", name: "ChartDB", description: "An Open Source online Entity-Relationship Diagram that visualize your database with a single query."},
          # %{id: "quickdbd", name: "QuickDBD", description: "Draw database diagrams by typing."},
          # %{id: "powerdesigner", name: "PowerDesigner", description: "Industry-leading data modeling tool manufactured by SAP."},
        ]
      },
      %{
        id: "database-design-language",
        name: "Database Design Language",
        keywords: "database design,database schema,dsl",
        tools: [
          %{
            id: "dbml",
            name: "DBML",
            title: "DBML vs AML, what are the differences?",
            image: "dbml-vs-aml.jpg",
            description: "DBML (Database Markup Language) is an open-source DSL to define and document database schemas.",
            pub: "2024-11-15"
          }
        ]
      },
      %{
        id: "sql-client",
        name: "SQL Client",
        keywords: "sql client",
        tools: [
          # %{id: "dbeaver", name: "DBeaver", description: "A free cross-platform database tool with support of many databases: MySQL, PostgreSQL, SQLite..."},
          # %{id: "datagrip", name: "DataGrip", description: "A powerful cross-platform tool for relational and NoSQL databases by JetBrains."},
          # %{id: "navicat", name: "Navicat", description: "Navicat is a robust, all-in-one solution for database development from a single application."},
          # %{id: "beekeeperstudio", name: "Beekeeper Studio", description: "The SQL Editor and Database Manager Of Your Dreams, easy to use and good looking SQL Client."},
          # %{id: "pgadmin", name: "pgAdmin", description: "The most popular and feature rich Open Source administration and development platform for PostgreSQL."},
        ]
      },
      %{
        id: "database-documentation",
        name: "Database Documentation",
        keywords: "database documentation",
        tools: [
          # %{id: "schemaspy", name: "SchemaSpy", description: "Document your database simply and easily with a statically generated site from your CI."}
        ]
      },
      %{
        id: "data-catalog",
        name: "Data Catalog",
        keywords: "data catalog",
        tools: [
          # %{id: "openmetadata", name: "OpenMetadata", description: "Open and unified metadata platform for data discovery, observability, and governance."},
          # %{id: "amundsen", name: "Amundsen", description: "Open source data discovery and metadata engine for analysts, data engineers and developers."},
          # %{id: "atlan", name: "Atlan", description: "Atlan is a metadata platform designed to cater to the needs of data-driven teams."}
        ]
      },
      %{
        id: "database-monitoring",
        name: "Database Monitoring",
        keywords: "database monitoring,proactive monitoring",
        tools: [
          # %{id: "datadog", name: "Datadog Database Monitoring", description: "Resolve issues and optimize inefficient query performance across entire database fleets."}
        ]
      },
      %{
        id: "dashboard",
        name: "Dashboard",
        keywords: "dashboard,data visualization,infographics",
        tools: [
          # %{id: "metabase", name: "Metabase", description: "Fast analytics with the friendly UX and integrated tooling to let your company explore data on their own."}
        ]
      }
    ]
  end

  def doc_pages do
    # path must be unique and not change as they are used for urls (SEO) and template names.
    [
      %{path: ["what-is-azimutt"], name: "What is Azimutt?"},
      %{path: ["create-your-project"], name: "Create your project", children: [%{path: ["export-your-database-schema"], name: "Export your database schema"}]},
      %{
        path: ["schema-exploration"],
        name: "Schema exploration",
        pub: "2024-12-05",
        children: [
          %{path: ["search"], name: "Search", pub: "2024-12-05"},
          %{path: ["follow-relations"], name: "Follow relations", pub: "2024-12-05"},
          %{path: ["find-path"], name: "Find path", pub: "2024-12-05"}
        ]
      },
      %{path: ["documentation"], name: "Database documentation", pub: "2024-12-05"},
      %{
        path: ["database-design"],
        name: "Database design",
        pub: "2024-10-07",
        mod: "2024-12-05",
        children: [
          %{
            path: ["aml"],
            name: "AML",
            pub: "2024-10-07",
            mod: "2024-12-05",
            children: [
              %{path: ["aml", "entities"], name: "Entities", pub: "2024-10-07"},
              %{path: ["aml", "relations"], name: "Relations", pub: "2024-10-07"},
              %{path: ["aml", "types"], name: "Types", pub: "2024-10-07"},
              %{path: ["aml", "namespaces"], name: "Namespaces", pub: "2024-10-07"},
              %{path: ["aml", "identifiers"], name: "Identifiers", pub: "2024-10-07"},
              %{path: ["aml", "properties"], name: "Properties", pub: "2024-10-07"},
              %{path: ["aml", "documentation"], name: "Documentation", pub: "2024-10-07"},
              %{path: ["aml", "comments"], name: "Comments", pub: "2024-10-07"},
              %{
                path: ["aml", "migration"],
                name: "Migration from v1",
                pub: "2024-10-07",
                children: [
                  %{path: ["aml", "v1"], name: "AML v1 (legacy)"}
                ]
              }
            ]
          }
        ]
      },
      %{path: ["layouts"], name: "Layouts", pub: "2024-12-06"},
      %{path: ["sources"], name: "Sources"},
      %{path: ["data-exploration"], name: "Data exploration"},
      %{path: ["database-analysis"], name: "Database analysis"},
      %{path: ["ai"], name: "AI integration"},
      %{path: ["keyboard-shortcuts"], name: "Keyboard shortcuts"},
      %{path: ["collaboration"], name: "Collaboration"},
      %{path: ["export"], name: "Export"},
      %{path: ["project-settings"], name: "Project settings"},
      %{path: ["api"], name: "API"},
      %{
        path: ["internals"],
        name: "Inside Azimutt",
        children: [
          %{path: ["infer-relations"], name: "Inferring relations"}
        ]
      },
      %{
        path: ["other-tools"],
        name: "Other tools",
        children: [
          %{path: ["cli"], name: "CLI"},
          %{path: ["gateway"], name: "Gateway"},
          %{path: ["converters"], name: "Converters"},
          %{path: ["vscode"], name: "VS Code extension", pub: "2024-12-05"},
          %{path: ["badge"], name: "GitHub badge"}
        ]
      },
      %{path: ["data-privacy"], name: "Data privacy", details: "how Azimutt keep your data safe"},
      %{path: ["installation"], name: "Installation"}
    ]
  end

  def doc_pages_flat, do: doc_pages() |> flatten_pages()

  defp flatten_pages(pages, parents \\ []) do
    pages
    |> Enum.flat_map(fn page ->
      children = if page[:children], do: page.children |> flatten_pages(parents ++ [page]), else: []
      [page |> Map.put(:parents, parents) | children]
    end)
  end
end
