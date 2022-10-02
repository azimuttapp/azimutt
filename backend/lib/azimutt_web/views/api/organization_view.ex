defmodule AzimuttWeb.Api.OrganizationView do
  use AzimuttWeb, :view
  alias Azimutt.Organizations.Organization
  alias AzimuttWeb.Utils.CtxParams

  # FIXME: how to pattern match on list or organizations?
  def render("index.json", %{organizations: organizations, ctx: %CtxParams{} = ctx}) do
    # FIXME: should we add a root object? like: {data: []}
    render_many(organizations, __MODULE__, "show.json", ctx: ctx)
  end

  def render("show.json", %{organization: %Organization{} = organization, ctx: %CtxParams{} = ctx}) do
    %{
      id: organization.id,
      slug: organization.slug,
      name: organization.name,
      logo: organization.logo,
      location: organization.location,
      description: organization.description,
      active_plan: organization.active_plan
    }
    |> put_projects(organization, ctx)
  end

  defp put_projects(json, organization, ctx) do
    if ctx.expand |> Enum.member?("projects") do
      project_ctx = ctx |> CtxParams.nested("projects")
      json |> Map.put(:projects, render_many(organization.projects, AzimuttWeb.Api.ProjectView, "show.json", ctx: project_ctx))
    else
      json
    end
  end
end
