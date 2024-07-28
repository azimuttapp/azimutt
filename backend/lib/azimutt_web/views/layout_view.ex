defmodule AzimuttWeb.LayoutView do
  use AzimuttWeb, :view
  alias Azimutt.Accounts
  alias Azimutt.CleverCloud
  alias Azimutt.Heroku
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Services.StripeSrv
  alias Azimutt.Utils.Result

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  # use:
  # https://frontendchecklist.io
  # https://search.google.com/structured-data/testing-tool
  # https://cards-dev.twitter.com/validator
  # https://developers.facebook.com/tools/debug
  # https://app.sistrix.com/en/serp-snippet-generator

  # max 55-70 chars
  def title(%{assigns: %{seo: %{title: title}}}), do: title <> " · Azimutt"
  def title(_conn), do: Azimutt.config(:seo_title)

  # max 150-300 chars
  def description(%{assigns: %{seo: %{description: description}}}), do: description
  def description(_conn), do: Azimutt.config(:seo_description)

  def keywords(%{assigns: %{seo: %{keywords: keywords}}}), do: keywords
  def keywords(_conn), do: Azimutt.config(:seo_keywords)

  def canonical(%{request_path: request_path} = conn), do: Routes.url(conn) <> request_path
  def canonical(_conn), do: AzimuttWeb.Endpoint.url()

  def og_type(%{assigns: %{seo: %{type: type}}}), do: type
  def og_type(_conn), do: "website"

  # ratio: 2:1, ex: 1200x600
  def og_image(%{assigns: %{seo: %{image: image}}}), do: image
  def og_image(conn), do: Routes.static_url(conn, "/images/open-graph.png")

  def twitter_card(%{assigns: %{seo: %{card: card}}}), do: card
  def twitter_card(_conn), do: "summary_large_image"

  def twitter_creator(%{assigns: %{seo: %{twitter_creator: twitter_creator}}}), do: twitter_creator
  def twitter_creator(_conn), do: twitter_site(%{})

  def twitter_site(%{assigns: %{seo: %{twitter_site: twitter_site}}}), do: twitter_site

  def twitter_site(_conn) do
    if Azimutt.config(:azimutt_twitter) do
      "@" <> (Azimutt.config(:azimutt_twitter) |> String.split("/") |> List.last())
    else
      ""
    end
  end

  def active(current_path, path) do
    real_path = path |> String.split("?") |> hd()

    if current_path === real_path do
      "hover:bg-gray-50 hover:text-gray-900 group flex items-center px-3 py-2 text-sm font-medium rounded-md bg-gray-100 text-gray-900"
    else
      "hover:bg-gray-50 hover:text-gray-900 group flex items-center px-3 py-2 text-sm font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900"
    end
  end

  def plan_badge(plan) do
    classes = "inline-flex items-center px-2.5 py-0.5 rounded-md text-sm font-medium"

    case "#{plan}" do
      "free" -> content_tag(:span, "Free plan", class: "#{classes} bg-gray-100 text-gray-800")
      "pro" -> content_tag(:span, "Pro plan", class: "#{classes} bg-yellow-100 text-yellow-800")
      "solo" -> content_tag(:span, "Solo plan", class: "#{classes} bg-yellow-100 text-yellow-800")
      "team" -> content_tag(:span, "Team plan", class: "#{classes} bg-emerald-100 text-emerald-800")
      "enterprise" -> content_tag(:span, "Enterprise plan", class: "#{classes} bg-indigo-100 text-indigo-800")
      _ -> content_tag(:span, "Unknown plan #{plan}", class: "#{classes} bg-red-100 text-red-800")
    end
  end

  def plan_badge_for(feature) do
    cond do
      plan_allowed(feature.free) -> "free"
      plan_allowed(feature.solo) -> "solo"
      plan_allowed(feature.team) -> "team"
      plan_allowed(feature.enterprise) -> "enterprise"
      true -> "none"
    end
    |> plan_badge()
  end

  defp plan_allowed(value), do: (is_boolean(value) && value) || (is_integer(value) && value > 0)

  def member_role(role) do
    OrganizationMember.roles()
    |> Enum.find(fn {_label, value} -> value == role end)
    |> Result.from_nillable()
    |> Result.map(fn {label, _value} -> label end)
    |> Result.or_else(role)
  end
end
