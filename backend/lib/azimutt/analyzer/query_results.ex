defmodule Azimutt.Analyzer.QueryResults do
  @moduledoc "Result of an arbitrary database query"
  use TypedStruct
  alias Azimutt.Analyzer.QueryResults.Column
  alias Azimutt.Analyzer.Schema.ColumnRef

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :query, String.t()
    field :columns, list(Column.t())
    field :rows, list(map())
  end

  typedstruct module: Column, enforce: true do
    @moduledoc false
    @derive Jason.Encoder
    field :name, String.t()
    # field :ref, ColumnRef.t()
  end
end
