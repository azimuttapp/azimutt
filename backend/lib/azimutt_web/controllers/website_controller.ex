defmodule AzimuttWeb.WebsiteController do
  use AzimuttWeb, :controller
  alias Azimutt.Accounts.User
  alias Azimutt.Projects
  alias Azimutt.Tracking
  alias Azimutt.Tracking.Event
  alias Azimutt.Utils.Result
  action_fallback AzimuttWeb.FallbackController

  def index(conn, _params) do
    # case conn |> last_used_project |> Result.filter_not(fn _p -> same_domain?(conn) end) do
    # {:ok, p} ->
    #   conn |> redirect(to: Routes.organization_path(conn, :show, p.organization_id))
    #   conn |> redirect(to: Routes.elm_path(conn, :project_show, p.organization_id, p.id))
    # _ ->
    if Azimutt.config(:skip_public_site) do
      conn.assigns.current_user
      |> Result.from_nillable()
      |> Result.map(fn _user -> conn |> redirect(to: Routes.user_dashboard_path(conn, :index)) end)
      |> Result.or_else(conn |> redirect(to: Routes.user_session_path(conn, :new)))
    else
      conn |> render("index.html")
    end

    # end
  end

  def aml(conn, _params) do
    render(conn, "aml.html",
      seo: %{
        title: "AML, the easiest DSL for database schemas",
        description: "If you ever designed a database schema on a whiteboard, AML is made for you ❤️. It's fast to learn and write, and can be translated to other dialects.",
        image: Routes.static_url(conn, "/images/og/aml.jpg")
      }
    )
  end

  def pricing(conn, _params), do: conn |> render("pricing.html", dark: true, seo: %{title: "Azimutt pricing"})

  def use_cases_index(conn, _params), do: conn |> render("use-cases/index.html")

  def use_cases_show(conn, %{"use_case_id" => use_case_id}) do
    Azimutt.showcase_usages()
    |> Enum.find(fn u -> u.id == use_case_id end)
    |> Result.from_nillable()
    |> Result.map(fn use_case ->
      conn |> render("use-cases/#{use_case_id}.html", use_case: use_case, seo: %{type: "article", title: use_case.title, description: use_case.description})
    end)
  end

  def features_index(conn, _params), do: conn |> render("features/index.html")

  def features_show(conn, %{"feature_id" => feature_id}) do
    features = Azimutt.showcase_features()

    features
    |> Enum.find_index(fn f -> f.id == feature_id end)
    |> Result.from_nillable()
    |> Result.map(fn index ->
      feature = features |> Enum.at(index)

      conn
      |> render("features/#{feature_id}.html",
        feature: feature,
        previous: if(index > 0, do: features |> Enum.at(index - 1), else: nil),
        next: features |> Enum.at(index + 1),
        seo: %{type: "article", title: feature.name, description: feature.description, image: Routes.static_url(conn, feature.image)}
      )
    end)
  end

  def connectors(conn, _params) do
    render(conn, "connectors/index.html",
      seo: %{
        title: "Discover all the connectors for Azimutt",
        description: "Azimutt is a database exploration and documentation tool made to help you understand and manage any database. We already have the mainstream ones, and we keep extending the integrations.",
        image: Routes.static_url(conn, "/images/og/connectors.jpg")
      }
    )
  end

  def connector_new(conn, _params), do: conn |> render("connectors/new.html", seo: %{type: "article", title: "Creating a new connector for Azimutt"})

  def connector(conn, %{"id" => id}) do
    Azimutt.connectors()
    |> Enum.find(fn c -> c.id == id end)
    |> Result.from_nillable()
    |> Result.map(fn connector ->
      render(conn, "connectors/#{connector.id}.html",
        connector: connector,
        seo: %{
          type: "article",
          title: "Explore #{connector.name} with Azimutt",
          image: Routes.static_url(conn, "/images/connectors/#{connector.id}-banner.png")
        }
      )
    end)
  end

  def converters(conn, _params) do
    conn
    |> render("converters/index.html",
      seo: %{
        title: "Azimutt dialect converters",
        description: "Azimutt is freely providing you converters to transform several database schema dialects from one to another 🤘"
      }
    )
  end

  def converter(conn, %{"from" => from}) do
    Azimutt.converters()
    |> Enum.find(fn c -> c.id == from end)
    |> Result.from_nillable()
    |> Result.map(fn converter ->
      conn
      |> render("converters/converter.html",
        converter: converter,
        seo: %{
          title: "#{converter.name} converter by Azimutt",
          description: "Azimutt is freely providing you converters to transform several database schema dialects from one to another 🤘",
          image: Routes.static_url(conn, "/images/converters/#{converter.id}.jpg")
        }
      )
    end)
  end

  def convert(conn, %{"from" => from_id, "to" => to_id}) do
    from_converter = Azimutt.converters() |> Enum.find(fn c -> c.id == from_id end) |> Result.from_nillable()
    to_converter = Azimutt.converters() |> Enum.find(fn c -> c.id == to_id end) |> Result.from_nillable()

    from_converter
    |> Result.flat_map(fn f -> to_converter |> Result.map(fn t -> {f, t} end) end)
    |> Result.map(fn {from, to} ->
      conn
      |> render("converters/convert.html",
        from: from,
        to: to,
        seo: %{
          title: "#{from.name} converter by Azimutt",
          description: "Azimutt is freely providing you converters to transform several database schema dialects from one to another 🤘",
          image: Routes.static_url(conn, "/images/converters/#{from.id}.jpg")
        }
      )
    end)
  end

  def comparisons(conn, _params) do
    conn |> render("comparisons/index.html", categories: Azimutt.comparisons())
  end

  def comparison_category(conn, %{"category" => category}) do
    Azimutt.comparisons()
    |> Enum.find(fn c -> c.id == category end)
    |> Result.from_nillable()
    |> Result.map(fn c ->
      conn |> render("comparisons/#{category}.html", category: c, seo: %{type: "article"})
    end)
  end

  def comparison(conn, %{"category" => category, "tool" => tool}) do
    Azimutt.comparisons()
    |> Enum.find(fn c -> c.id == category end)
    |> Result.from_nillable()
    |> Result.flat_map(fn c ->
      c.tools
      |> Enum.find(fn t -> t.id == tool end)
      |> Result.from_nillable()
      |> Result.map(fn t ->
        conn
        |> render("comparisons/#{t.id}.html",
          category: c,
          tool: t,
          seo: %{
            type: "article",
            title: t[:title] || "#{t.name} vs Azimutt, which database tool is right for you?",
            description: "Looking for a #{t.name} alternative? Or just shopping around for a #{c.name}? Compare Azimutt and #{t.name} to discover which is the best database tool for you.",
            image: Routes.static_url(conn, "/images/comparisons/#{t[:image] || "#{t.id}-vs-azimutt.jpg"}"),
            published: t.pub,
            keywords: t[:keywords] || c[:keywords]
          }
        )
      end)
    end)
  end

  def docs(conn, _params) do
    pages = Azimutt.doc_pages()

    conn
    |> render("docs/index.html",
      page: %{path: ["index"], name: "Azimutt Documentation", children: pages, parents: []},
      prev: nil,
      next: pages |> Enum.at(0),
      seo: %{
        type: "article",
        title: "Azimutt documentation"
      }
    )
  end

  def doc(conn, %{"path" => path}) do
    slug = path |> Enum.join("/")
    pages = Azimutt.doc_pages_flat()

    pages
    |> Enum.find_index(fn p -> Enum.join(p.path, "/") == slug end)
    |> Result.from_nillable()
    |> Result.map(fn index ->
      page = pages |> Enum.at(index)

      conn
      |> render("docs/#{slug}.html",
        page: page,
        prev: if(index > 0, do: pages |> Enum.at(index - 1), else: nil),
        next: pages |> Enum.at(index + 1),
        seo: %{
          type: "article",
          title: "Azimutt documentation > " <> (page.parents |> Enum.map_join("", fn p -> p.name <> " > " end)) <> page.name
        }
      )
    end)
  end

  def last(conn, _params) do
    case conn |> last_used_project do
      {:ok, p} -> conn |> redirect(to: Routes.elm_path(conn, :project_show, p.organization_id, p.id))
      _ -> conn |> redirect(to: Routes.user_dashboard_path(conn, :index))
    end
  end

  defp last_used_project(conn) do
    with {:ok, %User{} = current_user} <- conn.assigns.current_user |> Result.from_nillable(),
         {:ok, %Event{} = event} <- Tracking.last_used_project(current_user),
         do: Projects.get_project(event.project_id, current_user)
  end

  defp same_domain?(conn) do
    conn |> get_req_header("referer") |> Enum.any?(fn h -> h |> String.contains?(Azimutt.config(:host)) end)
  end

  def portal(conn, _params), do: conn |> render("portal.html")
  def portal_subscribed(conn, _params), do: conn |> render("portal-subscribed.html")
  def terms(conn, _params), do: conn |> render("terms.html")
  def privacy(conn, _params), do: conn |> render("privacy.html")
  def resources(conn, _params), do: conn |> render("resources.html")
end
