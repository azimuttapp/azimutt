# keep sync with frontend/ts-src/types/stats.ts & frontend/src/Models/Project/TableStats.elm
defmodule Azimutt.Analyzer.TableStats do
  @moduledoc "Statistics for a table"
  use TypedStruct

  typedstruct enforce: true do
    @derive Jason.Encoder
    field :schema, String.t()
    field :table, String.t()
    field :rows, integer()
    field :sample_values, map()
  end
end
