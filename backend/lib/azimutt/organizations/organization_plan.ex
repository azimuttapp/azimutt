defmodule Azimutt.Organizations.OrganizationPlan do
  @moduledoc false
  use TypedStruct
  alias Azimutt.Organizations.OrganizationPlan

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :id, atom()
    field :name, String.t()
    field :layouts, integer() | nil
    field :colors, boolean()
    field :db_analysis, boolean()
    field :db_access, boolean()
  end

  def free do
    # MUST stay in sync with frontend/src/Models/Plan.elm#free
    %OrganizationPlan{
      id: :free,
      name: "Free plan",
      layouts: Azimutt.config(:free_plan_layouts),
      colors: false,
      db_analysis: false,
      db_access: false
    }
  end

  def team do
    %OrganizationPlan{
      id: :team,
      name: "Team plan",
      layouts: nil,
      colors: true,
      db_analysis: true,
      db_access: true
    }
  end
end
