defmodule Azimutt.Organizations.OrganizationPlan do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Organizations.OrganizationPlan

  # MUST stay in sync with frontend/ts-src/types/organization.ts & frontend/src/Models/Plan.elm
  typedstruct enforce: true do
    @derive Jason.Encoder
    field :id, atom()
    field :name, String.t()
    field :layouts, integer() | nil
    field :memos, integer() | nil
    field :groups, integer() | nil
    field :colors, boolean()
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
      layouts: Azimutt.config(:free_plan_layouts),
      memos: Azimutt.config(:free_plan_memos),
      groups: Azimutt.config(:free_plan_groups),
      colors: Azimutt.config(:free_plan_colors),
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
      layouts: nil,
      memos: nil,
      groups: nil,
      colors: true,
      private_links: true,
      sql_export: true,
      db_analysis: true,
      db_access: true,
      streak: 0
    }
  end
end
