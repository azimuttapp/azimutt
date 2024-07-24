defmodule Azimutt.Organizations.OrganizationPlan do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Organizations.OrganizationPlan

  # MUST stay in sync with libs/models/src/legacy/legacyProject.ts & frontend/src/Models/Plan.elm
  typedstruct enforce: true do
    @derive Jason.Encoder
    field :id, atom()
    field :name, String.t()
    field :data_exploration, boolean()
    field :colors, boolean()
    field :aml, boolean()
    field :schema_export, boolean()
    field :ai, boolean()
    field :analysis, String.t()
    field :project_export, boolean()
    field :projects, integer() | nil
    field :project_dbs, integer() | nil
    field :project_layouts, integer() | nil
    field :layout_tables, integer() | nil
    field :project_doc, integer() | nil
    field :project_share, boolean()
    field :streak, integer()
  end

  def build(plan) do
    %OrganizationPlan{
      id: Azimutt.plans()[plan].id,
      name: Azimutt.plans()[plan].name,
      data_exploration: Azimutt.features().data_exploration[plan],
      colors: Azimutt.features().colors[plan],
      aml: Azimutt.features().aml[plan],
      schema_export: Azimutt.features().schema_export[plan],
      ai: Azimutt.features().ai[plan],
      analysis: Azimutt.features().analysis[plan],
      project_export: Azimutt.features().project_export[plan],
      projects: Azimutt.features().projects[plan],
      project_dbs: Azimutt.features().project_dbs[plan],
      project_layouts: Azimutt.features().project_layouts[plan],
      layout_tables: Azimutt.features().layout_tables[plan],
      project_doc: Azimutt.features().project_doc[plan],
      project_share: Azimutt.features().project_share[plan],
      streak: 0
    }
  end
end
