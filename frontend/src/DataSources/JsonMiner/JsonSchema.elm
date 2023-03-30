module DataSources.JsonMiner.JsonSchema exposing (JsonSchema, decode, encode, jsonSchema)

import DataSources.JsonMiner.Models.JsonRelation as JsonRelation exposing (JsonRelation)
import DataSources.JsonMiner.Models.JsonTable as JsonTable exposing (JsonTable)
import DataSources.JsonMiner.Models.JsonType as JsonType exposing (JsonType)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode


type alias JsonSchema =
    { tables : List JsonTable
    , relations : List JsonRelation
    , types : List JsonType
    }


decode : Decode.Decoder JsonSchema
decode =
    Decode.map3 JsonSchema
        (Decode.field "tables" (Decode.list JsonTable.decode))
        (Decode.field "relations" (Decode.list JsonRelation.decode))
        (Decode.defaultField "types" (Decode.list JsonType.decode) [])


encode : JsonSchema -> Value
encode value =
    Encode.notNullObject
        [ ( "tables", value.tables |> Encode.list JsonTable.encode )
        , ( "relations", value.relations |> Encode.list JsonRelation.encode )
        , ( "types", value.types |> Encode.withDefault (Encode.list JsonType.encode) [] )
        ]


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
          "columns": {"type": "array", "items": {"$ref": "/column"}},
          "primaryKey": {"$ref": "/primaryKey"},
          "uniques": {"type": "array", "items": {"$ref": "/unique"}},
          "indexes": {"type": "array", "items": {"$ref": "/index"}},
          "checks": {"type": "array", "items": {"$ref": "/check"}},
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
          "src": {"$ref": "/columnRef"},
          "ref": {"$ref": "/columnRef"}
        }
      }
    },
    "types": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["schema", "name"],
        "additionalProperties": false,
        "properties": {
          "schema": {"type": "string"},
          "name": {"type": "string"},
          "values": {"type": "array", "items": {"type": "string"}},
          "definition": {"type": "string"}
        },
        "oneOf": [
          {"required": ["values"]},
          {"required": ["definition"]}
        ]
      }
    }
  },
  "$defs": {
    "column": {
      "$id": "/column",
      "type": "object",
      "required": ["name", "type"],
      "additionalProperties": false,
      "properties": {
        "name": {"type": "string"},
        "type": {"type": "string"},
        "nullable": {"type": "boolean"},
        "default": {"type": "string"},
        "comment": {"type": "string"},
        "columns": {"type": "array", "items": {"$ref": "/column"}}
      }
    },
    "primaryKey": {
      "$id": "/primaryKey",
      "type": "object",
      "required": ["columns"],
      "additionalProperties": false,
      "properties": {
        "name": {"type": "string"},
        "columns": {"type": "array", "items": {"type": "string"}}
      }
    },
    "unique": {
      "$id": "/unique",
      "type": "object",
      "required": ["columns"],
      "additionalProperties": false,
      "properties": {
        "name": {"type": "string"},
        "columns": {"type": "array", "items": {"type": "string"}},
        "definition": {"type": "string"}
      }
    },
    "index": {
      "$id": "/index",
      "type": "object",
      "required": ["columns"],
      "additionalProperties": false,
      "properties": {
        "name": {"type": "string"},
        "columns": {"type": "array", "items": {"type": "string"}},
        "definition": {"type": "string"}
      }
    },
    "check": {
      "$id": "/check",
      "type": "object",
      "required": ["columns"],
      "additionalProperties": false,
      "properties": {
        "name": {"type": "string"},
        "columns": {"type": "array", "items": {"type": "string"}},
        "predicate": {"type": "string"}
      }
    },
    "columnRef": {
      "$id": "/columnRef",
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
}"""
