defmodule AzimuttWeb.Api.OrganizationView do
  use AzimuttWeb, :view
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias AzimuttWeb.Utils.CtxParams

  # FIXME: how to pattern match on list of organizations?
  def render("index.json", %{organizations: organizations, current_user: %User{} = current_user, ctx: %CtxParams{} = ctx}) do
    render_many(organizations, __MODULE__, "show.json", maybe_current_user: current_user, ctx: ctx)
  end

  def render("show.json", %{organization: %Organization{} = organization, maybe_current_user: maybe_current_user, ctx: %CtxParams{} = ctx}) do
    %{
      id: organization.id,
      slug: organization.slug,
      name: organization.name,
      logo: organization.logo,
      description: organization.description
    }
    |> put_plan(organization, maybe_current_user, ctx)
    |> put_projects(organization, maybe_current_user, ctx)
    |> put_clever_cloud_resource(organization, ctx)
    |> put_heroku_resource(organization, ctx)
  end

  def render("table_colors.json", %{tweet: tweet, errors: errors}) do
    %{
      tweet: tweet.text,
      errors: errors
    }
  end

  defp put_plan(json, %Organization{} = organization, maybe_current_user, %CtxParams{} = ctx) do
    if ctx.expand |> Enum.member?("plan") do
      {:ok, plan} = Organizations.get_organization_plan(organization, maybe_current_user)
      json |> Map.put(:plan, plan)
    else
      json
    end
  end

  defp put_projects(json, %Organization{} = organization, maybe_current_user, %CtxParams{} = ctx) do
    if ctx.expand |> Enum.member?("projects") do
      project_ctx = ctx |> CtxParams.nested("projects")
      json |> Map.put(:projects, render_many(organization.projects, AzimuttWeb.Api.ProjectView, "show.json", maybe_current_user: maybe_current_user, ctx: project_ctx))
    else
      json
    end
  end

  defp put_clever_cloud_resource(json, %Organization{} = organization, %CtxParams{} = _ctx) do
    if organization.clever_cloud_resource do
      json |> Map.put(:clever_cloud, %{id: organization.clever_cloud_resource.id})
    else
      json
    end
  end

  defp put_heroku_resource(json, %Organization{} = organization, %CtxParams{} = _ctx) do
    if organization.heroku_resource do
      json |> Map.put(:heroku, %{id: organization.heroku_resource.id})
    else
      json
    end
  end
end
