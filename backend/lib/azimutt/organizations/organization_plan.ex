defmodule Azimutt.Organizations.OrganizationPlan do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Organizations.OrganizationPlan

  # MUST stay in sync with libs/models/src/legacy/legacyProject.ts & frontend/src/Models/Plan.elm
  typedstruct enforce: true do
    @derive Jason.Encoder
    field :id, atom()
    field :name, String.t()
    field :projects, integer() | nil
    field :layouts, integer() | nil
    field :layout_tables, integer() | nil
    field :memos, integer() | nil
    field :groups, integer() | nil
    field :colors, boolean()
    field :local_save, boolean()
    field :private_links, boolean()
    field :sql_export, boolean()
    field :db_analysis, boolean()
    field :db_access, boolean()
    field :streak, integer()
  end

  def free do
    # MUST stay in sync with frontend/src/Models/Plan.elm#free
    %OrganizationPlan{
      id: :free,
      name: "Free plan",
      projects: Azimutt.config(:free_plan_projects),
      layouts: Azimutt.config(:free_plan_layouts),
      layout_tables: Azimutt.config(:free_plan_layout_tables),
      memos: Azimutt.config(:free_plan_memos),
      groups: Azimutt.config(:free_plan_groups),
      colors: Azimutt.config(:free_plan_colors),
      local_save: Azimutt.config(:free_plan_local_save),
      private_links: Azimutt.config(:free_plan_private_links),
      sql_export: Azimutt.config(:free_plan_sql_export),
      db_analysis: Azimutt.config(:free_plan_db_analysis),
      db_access: Azimutt.config(:free_plan_db_access),
      streak: 0
    }
  end

  def pro do
    %OrganizationPlan{
      id: :pro,
      name: "Pro plan",
      projects: nil,
      layouts: nil,
      layout_tables: nil,
      memos: nil,
      groups: nil,
      colors: true,
      local_save: true,
      private_links: true,
      sql_export: true,
      db_analysis: true,
      db_access: true,
      streak: 0
    }
  end
end
