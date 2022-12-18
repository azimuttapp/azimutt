defmodule Azimutt.Analyzer.QueryResults do
  @moduledoc "Result of an arbitrary database query"
  use TypedStruct

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :query, String.t()
    field :columns, list(String.t())
    field :values, list(list(any()))
  end
end
