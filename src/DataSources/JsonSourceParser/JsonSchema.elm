module DataSources.JsonSourceParser.JsonSchema exposing (JsonSchema, decode, jsonSchema)

import DataSources.JsonSourceParser.Models.JsonRelation as JsonRelation exposing (JsonRelation)
import DataSources.JsonSourceParser.Models.JsonTable as JsonTable exposing (JsonTable)
import Json.Decode as Decode


type alias JsonSchema =
    { tables : List JsonTable
    , relations : List JsonRelation
    }


decode : Decode.Decoder JsonSchema
decode =
    Decode.map2 JsonSchema
        (Decode.field "tables" (Decode.list JsonTable.decode))
        (Decode.field "relations" (Decode.list JsonRelation.decode))


jsonSchema : String
jsonSchema =
    """{
  "type": "object",
  "required": ["tables", "relations"],
  "additionalProperties": false,
  "properties": {
    "tables": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["schema", "table", "columns"],
        "additionalProperties": false,
        "properties": {
          "schema": {"type": "string"},
          "table": {"type": "string"},
          "view": {"type": "boolean"},
          "columns": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["name", "type"],
              "additionalProperties": false,
              "properties": {
                "name": {"type": "string"},
                "type": {"type": "string"},
                "nullable": {"type": "boolean"},
                "default": {"type": "string"},
                "comment": {"type": "string"}
              }
            }
          },
          "primaryKey": {
            "type": "object",
            "required": ["columns"],
            "additionalProperties": false,
            "properties": {
              "name": {"type": "string"},
              "columns": {"type": "array", "items": {"type": "string"}}
            }
          },
          "uniques": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["columns"],
              "additionalProperties": false,
              "properties": {
                "name": {"type": "string"},
                "columns": {"type": "array", "items": {"type": "string"}},
                "definition": {"type": "string"}
              }
            }
          },
          "indexes": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["columns"],
              "additionalProperties": false,
              "properties": {
                "name": {"type": "string"},
                "columns": {"type": "array", "items": {"type": "string"}},
                "definition": {"type": "string"}
              }
            }
          },
          "checks": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["columns"],
              "additionalProperties": false,
              "properties": {
                "name": {"type": "string"},
                "columns": {"type": "array", "items": {"type": "string"}},
                "predicate": {"type": "string"}
              }
            }
          },
          "comment": {"type": "string"}
        }
      }
    },
    "relations": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "src", "ref"],
        "additionalProperties": false,
        "properties": {
          "name": {"type": "string"},
          "src": {
            "type": "object",
            "required": ["schema", "table", "column"],
            "additionalProperties": false,
            "properties": {
              "schema": {"type": "string"},
              "table": {"type": "string"},
              "column": {"type": "string"}
            }
          },
          "ref": {
            "type": "object",
            "required": ["schema", "table", "column"],
            "additionalProperties": false,
            "properties": {
              "schema": {"type": "string"},
              "table": {"type": "string"},
              "column": {"type": "string"}
            }
          }
        }
      }
    }
  }
}"""
