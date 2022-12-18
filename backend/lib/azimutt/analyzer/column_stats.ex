defmodule Azimutt.Analyzer.ColumnStats do
  @moduledoc "Statistics for a column"
  use TypedStruct

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :schema, String.t()
    field :table, String.t()
    field :column, String.t()
    field :type, String.t()
    field :rows, pos_integer()
    field :nulls, pos_integer()
    field :cardinality, pos_integer()
    # field :min, any()
    # field :max, any()
    field :common_values, list(ValueCount.t())
    # field :random_values, list(any())
  end

  typedstruct module: ValueCount, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :value, any()
    field :count, pos_integer()
  end
end
