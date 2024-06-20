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
        cta: "Explore your db",
        link: "/new"
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
          "Database design",
          "Schema export",
          "Long term usage"
        ],
        cta: "Start free trial",
        link: "/subscribe/solo/:freq"
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
        cta: "Start free trial",
        link: "/subscribe/team/:freq"
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
        cta: "Contact us",
        link: "mailto:#{Azimutt.config(:support_email)}"
      },
      pro: %{
        id: :pro,
        name: "Pro",
        monthly: 13,
        yearly: 13,
        features: [],
        cta: "Start free trial"
      }
    }
  end

  def active_plans, do: [plans().free, plans().solo, plans().team, plans().enterprise]

  # MUST stay in sync with frontend/src/Conf.elm (`features`)
  def limits do
    %{
      # Database features
      schema_exploration: %{name: "Schema exploration", free: true, solo: true, team: true, enterprise: true},
      data_exploration: %{name: "Data exploration", free: true, solo: true, team: true, enterprise: true},
      colors: %{name: "Custom colors", free: false, solo: true, team: true, enterprise: true},
      aml: %{name: "Database design (AML)", free: false, solo: true, team: true, enterprise: true},
      # saved_queries: %{name: "Saved queries", free: false, solo: false, team: false, enterprise: true, description: "Soon... Save and share useful queries."},
      # dashboard: %{name: "Dashboard", free: false, solo: false, team: false, enterprise: true, description: "Soon... Visually see query results."},
      # db_stat_history: %{name: "Stats history", free: false, solo: false, team: false, enterprise: true, description: "Soon... Keep evolutions of database stats."},
      schema_export: %{name: "Export schema", free: false, solo: true, team: true, enterprise: true, description: "Export your schema as SQL, AML or JSON."},
      ai: %{name: "AI features", free: false, solo: false, team: true, enterprise: true},
      analysis: %{
        name: "Database analysis",
        free: "preview",
        solo: "preview",
        team: "snapshot",
        enterprise: "trends",
        description: "See top 3 suggestions with preview, all suggestions with snapshot and compute evolution with trends."
      },
      project_export: %{name: "Export project", free: false, solo: false, team: true, enterprise: true},
      # Product quotas
      users: %{name: "Max users", free: 1, solo: 1, team: 5, enterprise: nil},
      projects: %{name: "Max projects", free: 1, solo: 1, team: 5, enterprise: nil, description: "0 means you can create a project but can't save it."},
      project_dbs: %{name: "Max db/project", free: 1, solo: 1, team: 3, enterprise: nil},
      project_layouts: %{name: "Max layout/project", free: 1, solo: 3, team: 20, enterprise: nil},
      layout_tables: %{name: "Max table/layout", free: 10, solo: 10, team: 40, enterprise: nil},
      project_doc: %{name: "Max doc/project", free: 10, solo: 10, team: 1000, enterprise: nil},
      # Extended integration
      project_share: %{name: "Sharing project", free: false, solo: false, team: false, enterprise: true, description: "Use private links and embed to share with guest users."},
      api: %{name: "API access", free: false, solo: false, team: false, enterprise: true, description: "Fetch and update sources and documentation programmatically."},
      sso: %{name: "SSO", free: false, solo: false, team: false, enterprise: true, description: "Soon..."},
      user_rights: %{name: "User rights", free: false, solo: false, team: false, enterprise: true, description: "Soon... Have read-only users in your organization."},
      gateway_custom: %{name: "Custom gateway", free: false, solo: false, team: false, enterprise: true, description: "Soon... Securely connect to your databases."},
      billing: %{name: "Flexible billing", free: false, solo: false, team: false, enterprise: true},
      support_on_premise: %{name: "On-premise support", free: false, solo: false, team: false, enterprise: true},
      support_enterprise: %{name: "Enterprise support", free: false, solo: false, team: false, enterprise: true, description: "Priority email, answer within 48h."},
      consulting: %{name: "1h expert consulting", free: false, solo: false, team: false, enterprise: true},
      roadmap: %{name: "Roadmap impact", free: "suggestions", solo: "suggestions", team: "suggestions", enterprise: "discussions"}
    }
  end

  def use_cases do
    [
      %{
        id: "explore",
        # cursor-arrow-ripple / document-magnifying-glass / eye / globe-europe-africa / magnifying-glass-circle / map / rectangle-group
        icon: "cursor-arrow-rays",
        name: "Explore",
        description: "The all-in-one tool to understand and design your database following your thought process."
      },
      %{
        id: "analyze",
        # check-badge / beaker / clipboard-document-check / finger-print / funnel
        icon: "shield-check",
        name: "Optimize",
        description: "Identify database design warts and automate any check to keep it consistent."
      },
      %{
        id: "document",
        # tag / archive-box / bars-3-center-left
        icon: "book-open",
        name: "Document",
        description: "Nice and contextual documentation for databases is now finally a reality."
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
