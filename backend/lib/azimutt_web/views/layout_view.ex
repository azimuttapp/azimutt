defmodule AzimuttWeb.LayoutView do
  use AzimuttWeb, :view
  alias Azimutt.Organizations.OrganizationPlan

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def title(%{assigns: %{page_title: page_title}}), do: page_title
  def title(_conn), do: Azimutt.config(:seo_title)

  def description(%{assigns: %{meta_description: meta_description}}), do: meta_description
  def description(_conn), do: Azimutt.config(:seo_description)

  def keywords(%{assigns: %{meta_keywords: meta_keywords}}), do: meta_keywords
  def keywords(_conn), do: Azimutt.config(:seo_keywords)

  def og_image(%{assigns: %{og_image: og_image}}), do: og_image
  def og_image(conn), do: Routes.static_url(conn, "/images/open-graph.png")

  def current_page_url(%{host: host, request_path: request_path}), do: "https://" <> host <> request_path
  def current_page_url(_conn), do: AzimuttWeb.Endpoint.url()

  def twitter_creator(%{assigns: %{twitter_creator: twitter_creator}}), do: twitter_creator
  def twitter_creator(_conn), do: twitter_site(%{})

  def twitter_site(%{assigns: %{twitter_site: twitter_site}}), do: twitter_site

  def twitter_site(_conn) do
    if Azimutt.config(:twitter_url) do
      "@" <> (Azimutt.config(:twitter_url) |> String.split("/") |> List.last())
    else
      ""
    end
  end

  def active(current_path, path) do
    if current_path === path do
      "hover:bg-gray-50 hover:text-gray-900 group flex items-center px-3 py-2 text-sm font-medium rounded-md bg-gray-100 text-gray-900"
    else
      "hover:bg-gray-50 hover:text-gray-900 group flex items-center px-3 py-2 text-sm font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900"
    end
  end

  def generate_organization_plan_badge(%OrganizationPlan{} = plan) do
    classes = "inline-flex items-center px-2.5 py-0.5 rounded-md text-sm font-medium"

    case plan.id do
      :free -> content_tag(:span, "Free plan", class: "#{classes} bg-gray-100 text-gray-800")
      :team -> content_tag(:span, "Team plan", class: "#{classes} bg-yellow-100 text-yellow-800")
      :enterprise -> content_tag(:span, "Enterprise plan", class: "#{classes} bg-purple-100 text-purple-800")
      _ -> content_tag(:span, "Unknown plan #{plan.id}", class: "#{classes} bg-red-100 text-red-800")
    end
  end
end
