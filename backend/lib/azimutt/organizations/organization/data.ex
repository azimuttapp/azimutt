defmodule Azimutt.Organizations.Organization.Data do
  @moduledoc false
  use Ecto.Schema

  # see https://hexdocs.pm/ecto/embedded-schemas.html
  @primary_key false
  embedded_schema do
    field :allow_colors, :string
    field :allow_aml, :boolean
    field :allow_schema_export, :boolean
    field :allow_ai, :boolean
    field :allow_analysis, :string
    field :allow_project_export, :boolean
    field :allowed_projects, :integer
    field :allowed_project_dbs, :integer
    field :allowed_project_layouts, :integer
    field :allowed_layout_tables, :integer
    field :allowed_project_doc, :integer
    field :allow_project_share, :boolean
  end

  def to_hash(data) do
    %{
      allow_colors: data.allow_colors,
      allow_aml: data.allow_aml,
      allow_schema_export: data.allow_schema_export,
      allow_ai: data.allow_ai,
      allow_analysis: data.allow_analysis,
      allow_project_export: data.allow_project_export,
      allowed_projects: data.allowed_projects,
      allowed_project_dbs: data.allowed_project_dbs,
      allowed_project_layouts: data.allowed_project_layouts,
      allowed_layout_tables: data.allowed_layout_tables,
      allowed_project_doc: data.allowed_project_doc,
      allow_project_share: data.allow_project_share
    }
  end
end
