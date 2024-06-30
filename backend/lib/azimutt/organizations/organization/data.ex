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
end
