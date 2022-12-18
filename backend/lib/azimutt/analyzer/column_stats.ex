defmodule Azimutt.Analyzer.ColumnStats do
  @moduledoc "Statistics for a column"
  use TypedStruct

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :schema, String.t()
    field :table, String.t()
    field :column, String.t()
    field :type, String.t()
    field :rows, integer()
    field :nulls, integer()
    field :cardinality, integer()
    # field :min, any()
    # field :max, any()
    field :common_values, map()
    # field :random_values, list(any())
  end
end
