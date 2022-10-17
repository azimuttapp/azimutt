defmodule AzimuttWeb.Api.OrganizationView do
  use AzimuttWeb, :view
  alias Azimutt.Organizations
  alias Azimutt.Organizations.Organization
  alias AzimuttWeb.Utils.CtxParams

  # FIXME: how to pattern match on list of organizations?
  def render("index.json", %{organizations: organizations, ctx: %CtxParams{} = ctx}) do
    render_many(organizations, __MODULE__, "show.json", ctx: ctx)
  end

  def render("show.json", %{organization: %Organization{} = organization, ctx: %CtxParams{} = ctx}) do
    %{
      id: organization.id,
      slug: organization.slug,
      name: organization.name,
      logo: organization.logo,
      location: organization.location,
      description: organization.description
    }
    |> put_plan(organization, ctx)
    |> put_projects(organization, ctx)
  end

  defp put_plan(json, %Organization{} = organization, %CtxParams{} = ctx) do
    if ctx.expand |> Enum.member?("plan") do
      {:ok, plan} = Organizations.get_organization_plan(organization)
      json |> Map.put(:plan, plan)
    else
      json
    end
  end

  defp put_projects(json, %Organization{} = organization, %CtxParams{} = ctx) do
    if ctx.expand |> Enum.member?("projects") do
      project_ctx = ctx |> CtxParams.nested("projects")
      json |> Map.put(:projects, render_many(organization.projects, AzimuttWeb.Api.ProjectView, "show.json", ctx: project_ctx))
    else
      json
    end
  end
end
