defmodule AzimuttWeb.Utils.JsonSchema do
  @moduledoc "JSON Schema helpers"
  alias Azimutt.Utils.Result

  def validate(json, schema) do
    # TODO: add the string uuid format validation
    ExJsonSchema.Validator.validate(schema, json)
    |> Result.map_both(
      fn errors -> %{errors: errors |> Enum.map(fn {error, path} -> %{path: path, error: error} end)} end,
      fn _ -> json end
    )
  end
end
