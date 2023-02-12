module DataSources.JsonMiner.Models.JsonTable exposing (JsonCheck, JsonColumn, JsonIndex, JsonNestedColumns(..), JsonPrimaryKey, JsonTable, JsonUnique, decode, decodeJsonColumn)

import Json.Decode as Decode exposing (Decoder)
import Libs.Json.Decode as Decode
import Libs.Nel exposing (Nel)


type alias JsonTable =
    { schema : String
    , table : String
    , view : Maybe Bool
    , columns : List JsonColumn
    , primaryKey : Maybe JsonPrimaryKey
    , uniques : List JsonUnique
    , indexes : List JsonIndex
    , checks : List JsonCheck
    , comment : Maybe String
    }


type alias JsonColumn =
    { name : String
    , kind : String
    , nullable : Maybe Bool
    , default : Maybe String
    , comment : Maybe String
    , columns : Maybe JsonNestedColumns
    }


type JsonNestedColumns
    = JsonNestedColumns (Nel JsonColumn)


type alias JsonPrimaryKey =
    { name : Maybe String
    , columns : Nel String
    }


type alias JsonUnique =
    { name : Maybe String
    , columns : Nel String
    , definition : Maybe String
    }


type alias JsonIndex =
    { name : Maybe String
    , columns : Nel String
    , definition : Maybe String
    }


type alias JsonCheck =
    { name : Maybe String
    , columns : List String
    , predicate : Maybe String
    }


decode : Decoder JsonTable
decode =
    Decode.map9 JsonTable
        (Decode.field "schema" Decode.string)
        (Decode.field "table" Decode.string)
        (Decode.maybeField "view" Decode.bool)
        (Decode.field "columns" (Decode.list decodeJsonColumn))
        (Decode.maybeField "primaryKey" decodeJsonPrimaryKey)
        (Decode.defaultField "uniques" (Decode.list decodeJsonUnique) [])
        (Decode.defaultField "indexes" (Decode.list decodeJsonIndex) [])
        (Decode.defaultField "checks" (Decode.list decodeJsonCheck) [])
        (Decode.maybeField "comment" Decode.string)


decodeJsonColumn : Decoder JsonColumn
decodeJsonColumn =
    -- exposed for tests
    Decode.map6 JsonColumn
        (Decode.field "name" Decode.string)
        (Decode.field "type" Decode.string)
        (Decode.maybeField "nullable" Decode.bool)
        (Decode.maybeField "default" Decode.string)
        (Decode.maybeField "comment" Decode.string)
        (Decode.maybeField "columns" decodeJsonNestedColumns)


decodeJsonNestedColumns : Decoder JsonNestedColumns
decodeJsonNestedColumns =
    Decode.map JsonNestedColumns
        (Decode.nel (Decode.lazy (\_ -> decodeJsonColumn)))


decodeJsonPrimaryKey : Decoder JsonPrimaryKey
decodeJsonPrimaryKey =
    Decode.map2 JsonPrimaryKey
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.nel Decode.string))


decodeJsonUnique : Decoder JsonUnique
decodeJsonUnique =
    Decode.map3 JsonUnique
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.nel Decode.string))
        (Decode.maybeField "definition" Decode.string)


decodeJsonIndex : Decoder JsonIndex
decodeJsonIndex =
    Decode.map3 JsonIndex
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.nel Decode.string))
        (Decode.maybeField "definition" Decode.string)


decodeJsonCheck : Decoder JsonCheck
decodeJsonCheck =
    Decode.map3 JsonCheck
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.list Decode.string))
        (Decode.maybeField "predicate" Decode.string)
