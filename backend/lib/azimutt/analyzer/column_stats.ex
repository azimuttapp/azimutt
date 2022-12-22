# keep sync with frontend/ts-src/types/stats.ts & frontend/src/Models/Project/ColumnStats.elm
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
    field :common_values, list(ValueCount.t())
    # field :random_values, list(any()) # TODO
    # TODO: for strings: min, max, min_len, max_len
    # TODO: for numbers: min, max, avg, median
    # TODO: for dates: min, max
    # TODO: for bools: /
    # TODO: for enums: /
  end

  typedstruct module: ValueCount, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :value, any()
    field :count, pos_integer()
  end
end
