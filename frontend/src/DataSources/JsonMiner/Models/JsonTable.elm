module DataSources.JsonMiner.Models.JsonTable exposing (JsonCheck, JsonColumn, JsonIndex, JsonNestedColumns(..), JsonPrimaryKey, JsonTable, JsonUnique, decode, decodeJsonColumn, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
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


encode : JsonTable -> Value
encode value =
    Encode.notNullObject
        [ ( "schema", value.schema |> Encode.string )
        , ( "table", value.table |> Encode.string )
        , ( "view", value.view |> Encode.maybe Encode.bool )
        , ( "columns", value.columns |> Encode.list encodeJsonColumn )
        , ( "primaryKey", value.primaryKey |> Encode.maybe encodeJsonPrimaryKey )
        , ( "uniques", value.uniques |> Encode.withDefault (Encode.list encodeJsonUnique) [] )
        , ( "indexes", value.indexes |> Encode.withDefault (Encode.list encodeJsonIndex) [] )
        , ( "checks", value.checks |> Encode.withDefault (Encode.list encodeJsonCheck) [] )
        , ( "comment", value.comment |> Encode.maybe Encode.string )
        ]


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


encodeJsonColumn : JsonColumn -> Value
encodeJsonColumn value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.string )
        , ( "type", value.kind |> Encode.string )
        , ( "nullable", value.nullable |> Encode.maybe Encode.bool )
        , ( "default", value.default |> Encode.maybe Encode.string )
        , ( "comment", value.comment |> Encode.maybe Encode.string )
        , ( "columns", value.columns |> Encode.maybe encodeJsonNestedColumns )
        ]


decodeJsonNestedColumns : Decoder JsonNestedColumns
decodeJsonNestedColumns =
    Decode.map JsonNestedColumns
        (Decode.nel (Decode.lazy (\_ -> decodeJsonColumn)))


encodeJsonNestedColumns : JsonNestedColumns -> Value
encodeJsonNestedColumns (JsonNestedColumns value) =
    value |> Encode.nel encodeJsonColumn


decodeJsonPrimaryKey : Decoder JsonPrimaryKey
decodeJsonPrimaryKey =
    Decode.map2 JsonPrimaryKey
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.nel Decode.string))


encodeJsonPrimaryKey : JsonPrimaryKey -> Value
encodeJsonPrimaryKey value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.maybe Encode.string )
        , ( "columns", value.columns |> Encode.nel Encode.string )
        ]


decodeJsonUnique : Decoder JsonUnique
decodeJsonUnique =
    Decode.map3 JsonUnique
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.nel Decode.string))
        (Decode.maybeField "definition" Decode.string)


encodeJsonUnique : JsonUnique -> Value
encodeJsonUnique value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.maybe Encode.string )
        , ( "columns", value.columns |> Encode.nel Encode.string )
        , ( "definition", value.definition |> Encode.maybe Encode.string )
        ]


decodeJsonIndex : Decoder JsonIndex
decodeJsonIndex =
    Decode.map3 JsonIndex
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.nel Decode.string))
        (Decode.maybeField "definition" Decode.string)


encodeJsonIndex : JsonIndex -> Value
encodeJsonIndex value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.maybe Encode.string )
        , ( "columns", value.columns |> Encode.nel Encode.string )
        , ( "definition", value.definition |> Encode.maybe Encode.string )
        ]


decodeJsonCheck : Decoder JsonCheck
decodeJsonCheck =
    Decode.map3 JsonCheck
        (Decode.maybeField "name" Decode.string)
        (Decode.field "columns" (Decode.list Decode.string))
        (Decode.maybeField "predicate" Decode.string)


encodeJsonCheck : JsonCheck -> Value
encodeJsonCheck value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.maybe Encode.string )
        , ( "columns", value.columns |> Encode.list Encode.string )
        , ( "predicate", value.predicate |> Encode.maybe Encode.string )
        ]
