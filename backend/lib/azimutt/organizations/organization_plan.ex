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
      data_exploration: Azimutt.limits().data_exploration[plan],
      colors: Azimutt.limits().colors[plan],
      aml: Azimutt.limits().aml[plan],
      schema_export: Azimutt.limits().schema_export[plan],
      ai: Azimutt.limits().ai[plan],
      analysis: Azimutt.limits().analysis[plan],
      project_export: Azimutt.limits().project_export[plan],
      projects: Azimutt.limits().projects[plan],
      project_dbs: Azimutt.limits().project_dbs[plan],
      project_layouts: Azimutt.limits().project_layouts[plan],
      layout_tables: Azimutt.limits().layout_tables[plan],
      project_doc: Azimutt.limits().project_doc[plan],
      project_share: Azimutt.limits().project_share[plan],
      streak: 0
    }
  end
end
