defmodule AzimuttWeb.Api.ProjectView do
  use AzimuttWeb, :view
  alias Azimutt.Projects.Project
  alias Azimutt.Projects.Project.Storage
  alias Azimutt.Projects.ProjectFile
  alias AzimuttWeb.Utils.CtxParams

  def render("index.json", %{projects: projects}) do
    render_many(projects, __MODULE__, "show.json", ctx: CtxParams.empty())
  end

  def render("show.json", %{project: %Project{} = project, ctx: %CtxParams{} = ctx}) do
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
    |> put_orga(project, ctx)
    |> put_content(project, ctx)
  end

  defp put_orga(json, %Project{} = project, %CtxParams{} = ctx) do
    if ctx.expand |> Enum.member?("organization") do
      orga_ctx = ctx |> CtxParams.nested("organization")
      json |> Map.put(:organization, render_one(project.organization, AzimuttWeb.Api.OrganizationView, "show.json", ctx: orga_ctx))
    else
      json
    end
  end

  defp put_content(json, %Project{} = project, %CtxParams{} = ctx) do
    if ctx.expand |> Enum.member?("content") do
      json |> Map.put(:content, get_content(project))
    else
      json
    end
  end

  defp get_content(%Project{} = project) do
    if project.storage_kind == Storage.remote() do
      # FIXME: handle spaces in name
      file_url = ProjectFile.url({project.file, project}, signed: true)

      if Mix.env() in [:dev, :test] do
        with {:ok, body} <- File.read("./#{file_url}"), do: body
      else
        HTTPoison.get!(file_url).body
      end
    else
      "{}"
    end
  end
end
