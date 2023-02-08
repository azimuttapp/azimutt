module Models.Project.TableStats exposing (TableStats, decode)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Models.Project.ColumnPath exposing (ColumnPathStr)
import Models.Project.ColumnValue as ColumnValue exposing (ColumnValue)
import Models.Project.SchemaName as SchemaName
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName as TableName


type alias TableStats =
    -- keep sync with frontend/ts-src/types/stats.ts & backend/lib/azimutt/analyzer/table_stats.ex
    { id : TableId
    , rows : Int
    , sampleValues : Dict ColumnPathStr ColumnValue
    }


decode : Decoder TableStats
decode =
    Decode.map3 TableStats
        decodeTableId
        (Decode.field "rows" Decode.int)
        (Decode.field "sample_values" (Decode.dict ColumnValue.decodeAny))


decodeTableId : Decoder TableId
decodeTableId =
    Decode.map2 (\s t -> ( s, t ))
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "table" TableName.decode)
