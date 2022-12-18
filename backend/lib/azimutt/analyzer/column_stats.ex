defmodule Azimutt.Analyzer.ColumnStats do
  @moduledoc "Statistics for a column"
  use TypedStruct

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :schema, String.t()
    field :table, String.t()
    field :column, String.t()
  end
end
