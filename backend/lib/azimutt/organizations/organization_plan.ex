defmodule Azimutt.Organizations.OrganizationPlan do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Organizations.OrganizationPlan

  # MUST stay in sync with frontend/src/Models/Plan.elm
  typedstruct enforce: true do
    @derive Jason.Encoder
    field :id, atom()
    field :name, String.t()
    field :layouts, integer() | nil
    field :memos, integer() | nil
    field :colors, boolean()
    field :private_links, boolean()
    field :db_analysis, boolean()
    field :db_access, boolean()
  end

  def free do
    # MUST stay in sync with frontend/src/Models/Plan.elm#free
    %OrganizationPlan{
      id: :free,
      name: "Free plan",
      layouts: Azimutt.config(:free_plan_layouts),
      memos: Azimutt.config(:free_plan_memos),
      colors: Azimutt.config(:free_plan_colors),
      private_links: Azimutt.config(:free_plan_private_links),
      db_analysis: Azimutt.config(:free_plan_db_analysis),
      db_access: Azimutt.config(:free_plan_db_access)
    }
  end

  def team do
    %OrganizationPlan{
      id: :team,
      name: "Team plan",
      layouts: nil,
      memos: nil,
      colors: true,
      private_links: true,
      db_analysis: true,
      db_access: true
    }
  end
end
