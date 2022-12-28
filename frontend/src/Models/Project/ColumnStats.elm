module Models.Project.ColumnStats exposing (ColumnStats, ColumnValueCount, decode)

import Json.Decode as Decode exposing (Decoder)
import Models.Project.ColumnId exposing (ColumnId)
import Models.Project.ColumnName as ColumnName
import Models.Project.ColumnType as ColumnType exposing (ColumnType)
import Models.Project.ColumnValue as ColumnValue exposing (ColumnValue)
import Models.Project.SchemaName as SchemaName
import Models.Project.TableName as TableName


type alias ColumnStats =
    -- keep sync with frontend/ts-src/types/stats.ts & backend/lib/azimutt/analyzer/column_stats.ex
    { id : ColumnId
    , kind : ColumnType
    , rows : Int
    , nulls : Int
    , cardinality : Int
    , commonValues : List ColumnValueCount
    }


type alias ColumnValueCount =
    { value : ColumnValue, count : Int }


decode : Decoder ColumnStats
decode =
    Decode.map6 ColumnStats
        decodeColumnId
        (Decode.field "type" ColumnType.decode)
        (Decode.field "rows" Decode.int)
        (Decode.field "nulls" Decode.int)
        (Decode.field "cardinality" Decode.int)
        (Decode.field "common_values" (Decode.list decodeColumnValueCount))


decodeColumnId : Decoder ColumnId
decodeColumnId =
    Decode.map3 (\s t c -> ( ( s, t ), c ))
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "table" TableName.decode)
        (Decode.field "column" ColumnName.decode)


decodeColumnValueCount : Decoder ColumnValueCount
decodeColumnValueCount =
    Decode.map2 ColumnValueCount
        (Decode.field "value" ColumnValue.decodeAny)
        (Decode.field "count" Decode.int)
