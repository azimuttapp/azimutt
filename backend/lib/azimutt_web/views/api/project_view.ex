defmodule AzimuttWeb.Api.ProjectView do
  use AzimuttWeb, :view
  alias Azimutt.Accounts.User
  alias Azimutt.Projects
  alias Azimutt.Projects.Project
  alias Azimutt.Utils.Result
  alias AzimuttWeb.Utils.CtxParams

  def render("index.json", %{projects: projects, current_user: %User{} = current_user}) do
    render_many(projects, __MODULE__, "show.json", maybe_current_user: current_user, ctx: CtxParams.empty())
  end

  def render("show.json", %{project: %Project{} = project, maybe_current_user: maybe_current_user, ctx: %CtxParams{} = ctx}) do
    %{
      id: project.id,
      slug: project.slug,
      name: project.name,
      description: project.description,
      encoding_version: project.encoding_version,
      storage_kind: project.storage_kind,
      visibility: project.visibility,
      nb_sources: project.nb_sources,
      nb_tables: project.nb_tables,
      nb_columns: project.nb_columns,
      nb_relations: project.nb_relations,
      nb_types: project.nb_types,
      nb_comments: project.nb_comments,
      nb_layouts: project.nb_layouts,
      nb_notes: project.nb_notes,
      nb_memos: project.nb_memos,
      # FIXME load `created_by` association to show it, and toggle it with expands (projects.created_by)
      created_at: project.created_at,
      updated_at: project.updated_at,
      archived_at: project.archived_at
    }
    |> put_orga(project, maybe_current_user, ctx)
    |> put_content(project, ctx)
  end

  defp put_orga(json, %Project{} = project, maybe_current_user, %CtxParams{} = ctx) do
    if ctx.expand |> Enum.member?("organization") do
      orga_ctx = ctx |> CtxParams.nested("organization")
      json |> Map.put(:organization, render_one(project.organization, AzimuttWeb.Api.OrganizationView, "show.json", maybe_current_user: maybe_current_user, ctx: orga_ctx))
    else
      json
    end
  end

  defp put_content(json, %Project{} = project, %CtxParams{} = ctx) do
    if ctx.expand |> Enum.member?("content") do
      Projects.get_project_content(project)
      |> Result.fold(fn _err -> json end, fn content -> json |> Map.put(:content, content) end)
    else
      json
    end
  end
end
