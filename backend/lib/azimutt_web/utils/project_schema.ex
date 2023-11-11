defmodule AzimuttWeb.Utils.ProjectSchema do
  @moduledoc "JSON Schema definition for project"

  # MUST stay in sync with frontend/ts-src/types/project.ts

  @type_schema %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["schema", "name", "value"],
    "properties" => %{
      "schema" => %{"type" => "string"},
      "name" => %{"type" => "string"},
      "value" => %{
        "anyOf" => [
          %{"type" => "object", "additionalProperties" => false, "required" => ["enum"], "properties" => %{"enum" => %{"type" => "array", "items" => %{"type" => "string"}}}},
          %{"type" => "object", "additionalProperties" => false, "required" => ["definition"], "properties" => %{"definition" => %{"type" => "string"}}}
        ]
      }
    }
  }

  @column_ref %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["table", "column"],
    "properties" => %{
      "table" => %{"type" => "string"},
      "column" => %{"type" => "string"}
    }
  }

  @relation %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["name", "src", "ref"],
    "properties" => %{
      "name" => %{"type" => "string"},
      "src" => @column_ref,
      "ref" => @column_ref
    }
  }

  @comment %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["text"],
    "properties" => %{
      "text" => %{"type" => "string"}
    }
  }

  @check %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["name", "columns"],
    "properties" => %{
      "name" => %{"type" => "string"},
      "columns" => %{"type" => "array", "items" => %{"type" => "string"}},
      "predicate" => %{"type" => "string"}
    }
  }

  @index %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["name", "columns"],
    "properties" => %{
      "name" => %{"type" => "string"},
      "columns" => %{"type" => "array", "items" => %{"type" => "string"}},
      "definition" => %{"type" => "string"}
    }
  }

  @unique %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["name", "columns"],
    "properties" => %{
      "name" => %{"type" => "string"},
      "columns" => %{"type" => "array", "items" => %{"type" => "string"}},
      "definition" => %{"type" => "string"}
    }
  }

  @primary_key %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["columns"],
    "properties" => %{
      "name" => %{"type" => "string"},
      "columns" => %{"type" => "array", "items" => %{"type" => "string"}}
    }
  }

  @column %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["name", "type"],
    "properties" => %{
      "name" => %{"type" => "string"},
      "type" => %{"type" => "string"},
      "nullable" => %{"type" => "boolean"},
      "default" => %{"type" => "string"},
      "comment" => @comment,
      "values" => %{"type" => "array", "items" => %{"type" => "string"}},
      # MUST include the column inside the `definitions` attribute in the global schema
      "columns" => %{"type" => "array", "items" => %{"$ref" => "#/definitions/column"}}
    }
  }

  @table %{
    "type" => "object",
    "additionalProperties" => false,
    "required" => ["schema", "table", "columns"],
    "properties" => %{
      "schema" => %{"type" => "string"},
      "table" => %{"type" => "string"},
      "view" => %{"type" => "boolean"},
      "columns" => %{"type" => "array", "items" => @column},
      "primaryKey" => @primary_key,
      "uniques" => %{"type" => "array", "items" => @unique},
      "indexes" => %{"type" => "array", "items" => @index},
      "checks" => %{"type" => "array", "items" => @check},
      "comment" => @comment
    }
  }

  def table, do: @table
  def column, do: @column
  def relation, do: @relation
  def type, do: @type_schema
end
