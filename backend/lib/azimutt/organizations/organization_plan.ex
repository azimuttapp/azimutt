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
end
