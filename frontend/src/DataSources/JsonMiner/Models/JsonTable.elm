module DataSources.JsonMiner.Models.JsonTable exposing (JsonCheck, JsonColumn, JsonColumnDbStats, JsonIndex, JsonNestedColumns(..), JsonPrimaryKey, JsonTable, JsonTableDbStats, JsonUnique, decode, decodeJsonColumn, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel exposing (Nel)
import Libs.Time as Time
import Models.Project.ColumnValue as ColumnValue exposing (ColumnValue)
import Time


type alias JsonTable =
    { schema : String
    , table : String
    , view : Maybe Bool
    , definition : Maybe String
    , columns : List JsonColumn
    , primaryKey : Maybe JsonPrimaryKey
    , uniques : List JsonUnique
    , indexes : List JsonIndex
    , checks : List JsonCheck
    , comment : Maybe String
    , stats : Maybe JsonTableDbStats
    }


type alias JsonTableDbStats =
    { rows : Maybe Int
    , size : Maybe Int
    , sizeIdx : Maybe Int
    , scanSeq : Maybe Int
    , scanSeqLast : Maybe Time.Posix
    , scanIdx : Maybe Int
    , scanIdxLast : Maybe Time.Posix
    , analyzeLast : Maybe Time.Posix
    , vacuumLast : Maybe Time.Posix
    }


type alias JsonColumn =
    { name : String
    , kind : String
    , nullable : Maybe Bool
    , default : Maybe String
    , comment : Maybe String
    , values : Maybe (Nel String)
    , columns : Maybe JsonNestedColumns
    , stats : Maybe JsonColumnDbStats
    }


type JsonNestedColumns
    = JsonNestedColumns (Nel JsonColumn)


type alias JsonColumnDbStats =
    { nulls : Maybe Float
    , bytesAvg : Maybe Float
    , cardinality : Maybe Float
    , commonValues : Maybe (List { value : ColumnValue, freq : Float })
    , histogram : Maybe (List ColumnValue)
    }


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
    Decode.map11 JsonTable
        (Decode.field "schema" Decode.string)
        (Decode.field "table" Decode.string)
        (Decode.maybeField "view" Decode.bool)
        (Decode.maybeField "definition" Decode.string)
        (Decode.field "columns" (Decode.list decodeJsonColumn))
        (Decode.maybeField "primaryKey" decodeJsonPrimaryKey)
        (Decode.defaultField "uniques" (Decode.list decodeJsonUnique) [])
        (Decode.defaultField "indexes" (Decode.list decodeJsonIndex) [])
        (Decode.defaultField "checks" (Decode.list decodeJsonCheck) [])
        (Decode.maybeField "comment" Decode.string)
        (Decode.maybeField "stats" decodeJsonTableDbStats)


encode : JsonTable -> Value
encode value =
    Encode.notNullObject
        [ ( "schema", value.schema |> Encode.string )
        , ( "table", value.table |> Encode.string )
        , ( "view", value.view |> Encode.maybe Encode.bool )
        , ( "definition", value.definition |> Encode.maybe Encode.string )
        , ( "columns", value.columns |> Encode.list encodeJsonColumn )
        , ( "primaryKey", value.primaryKey |> Encode.maybe encodeJsonPrimaryKey )
        , ( "uniques", value.uniques |> Encode.withDefault (Encode.list encodeJsonUnique) [] )
        , ( "indexes", value.indexes |> Encode.withDefault (Encode.list encodeJsonIndex) [] )
        , ( "checks", value.checks |> Encode.withDefault (Encode.list encodeJsonCheck) [] )
        , ( "comment", value.comment |> Encode.maybe Encode.string )
        , ( "stats", value.stats |> Encode.maybe encodeJsonTableDbStats )
        ]


decodeJsonColumn : Decoder JsonColumn
decodeJsonColumn =
    -- exposed for tests
    Decode.map8 JsonColumn
        (Decode.field "name" Decode.string)
        (Decode.field "type" Decode.string)
        (Decode.maybeField "nullable" Decode.bool)
        (Decode.maybeField "default" Decode.string)
        (Decode.maybeField "comment" Decode.string)
        (Decode.maybeField "values" (Decode.nel Decode.string))
        (Decode.maybeField "columns" decodeJsonNestedColumns)
        (Decode.maybeField "stats" decodeJsonColumnDbStats)


encodeJsonColumn : JsonColumn -> Value
encodeJsonColumn value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.string )
        , ( "type", value.kind |> Encode.string )
        , ( "nullable", value.nullable |> Encode.maybe Encode.bool )
        , ( "default", value.default |> Encode.maybe Encode.string )
        , ( "comment", value.comment |> Encode.maybe Encode.string )
        , ( "values", value.values |> Encode.maybe (Encode.nel Encode.string) )
        , ( "columns", value.columns |> Encode.maybe encodeJsonNestedColumns )
        , ( "stats", value.stats |> Encode.maybe encodeJsonColumnDbStats )
        ]


decodeJsonNestedColumns : Decoder JsonNestedColumns
decodeJsonNestedColumns =
    Decode.map JsonNestedColumns
        (Decode.nel (Decode.lazy (\_ -> decodeJsonColumn)))


encodeJsonNestedColumns : JsonNestedColumns -> Value
encodeJsonNestedColumns (JsonNestedColumns value) =
    value |> Encode.nel encodeJsonColumn


decodeJsonColumnDbStats : Decoder JsonColumnDbStats
decodeJsonColumnDbStats =
    Decode.map5 JsonColumnDbStats
        (Decode.maybeField "nulls" Decode.float)
        (Decode.maybeField "bytesAvg" Decode.float)
        (Decode.maybeField "cardinality" Decode.float)
        (Decode.maybeField "commonValues" (Decode.list decodeJsonColumnDbStatsValue))
        (Decode.maybeField "histogram" (Decode.list ColumnValue.decodeAny))


encodeJsonColumnDbStats : JsonColumnDbStats -> Value
encodeJsonColumnDbStats value =
    Encode.notNullObject
        [ ( "nulls", value.nulls |> Encode.maybe Encode.float )
        , ( "bytesAvg", value.bytesAvg |> Encode.maybe Encode.float )
        , ( "cardinality", value.cardinality |> Encode.maybe Encode.float )
        , ( "commonValues", value.commonValues |> Encode.maybe (Encode.list encodeJsonColumnDbStatsValue) )
        , ( "histogram", value.histogram |> Encode.maybe (Encode.list ColumnValue.encode) )
        ]


decodeJsonColumnDbStatsValue : Decoder { value : ColumnValue, freq : Float }
decodeJsonColumnDbStatsValue =
    Decode.map2 (\v f -> { value = v, freq = f })
        (Decode.field "value" ColumnValue.decodeAny)
        (Decode.field "freq" Decode.float)


encodeJsonColumnDbStatsValue : { value : ColumnValue, freq : Float } -> Value
encodeJsonColumnDbStatsValue value =
    Encode.notNullObject
        [ ( "value", value.value |> ColumnValue.encode )
        , ( "freq", value.freq |> Encode.float )
        ]


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


decodeJsonTableDbStats : Decoder JsonTableDbStats
decodeJsonTableDbStats =
    Decode.map9 JsonTableDbStats
        (Decode.maybeField "rows" Decode.int)
        (Decode.maybeField "size" Decode.int)
        (Decode.maybeField "sizeIdx" Decode.int)
        (Decode.maybeField "scanSeq" Decode.int)
        (Decode.maybeField "scanSeqLast" Time.decode)
        (Decode.maybeField "scanIdx" Decode.int)
        (Decode.maybeField "scanIdxLast" Time.decode)
        (Decode.maybeField "analyzeLast" Time.decode)
        (Decode.maybeField "vacuumLast" Time.decode)


encodeJsonTableDbStats : JsonTableDbStats -> Value
encodeJsonTableDbStats value =
    Encode.notNullObject
        [ ( "rows", value.rows |> Encode.maybe Encode.int )
        , ( "size", value.size |> Encode.maybe Encode.int )
        , ( "sizeIdx", value.sizeIdx |> Encode.maybe Encode.int )
        , ( "scanSeq", value.scanSeq |> Encode.maybe Encode.int )
        , ( "scanSeqLast", value.scanSeqLast |> Encode.maybe Time.encodeIso )
        , ( "scanIdx", value.scanIdx |> Encode.maybe Encode.int )
        , ( "scanIdxLast", value.scanIdxLast |> Encode.maybe Time.encodeIso )
        , ( "analyzeLast", value.analyzeLast |> Encode.maybe Time.encodeIso )
        , ( "vacuumLast", value.vacuumLast |> Encode.maybe Time.encodeIso )
        ]
