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
      id: Azimutt.plans().free.id,
      name: Azimutt.plans().free.name,
      projects: Azimutt.limits().projects.free,
      layouts: Azimutt.limits().project_layouts.free,
      layout_tables: Azimutt.limits().layout_tables.free,
      memos: Azimutt.limits().project_doc.free,
      groups: Azimutt.limits().project_doc.free,
      colors: Azimutt.limits().colors.free,
      local_save: false,
      private_links: Azimutt.limits().project_share.free,
      sql_export: Azimutt.limits().schema_export.free,
      db_analysis: Azimutt.limits().analysis.free != "preview",
      db_access: Azimutt.limits().data_exploration.free,
      streak: 0
    }
  end

  def pro do
    %OrganizationPlan{
      id: :pro,
      name: "Pro",
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
