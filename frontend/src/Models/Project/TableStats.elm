module Models.Project.TableStats exposing (TableStats, decode)

import Json.Decode as Decode exposing (Decoder)
import Models.Project.SchemaName as SchemaName
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName as TableName


type alias TableStats =
    { id : TableId
    , rows : Int
    }


decode : Decoder TableStats
decode =
    Decode.map2 TableStats
        decodeTableId
        (Decode.field "rows" Decode.int)


decodeTableId : Decoder TableId
decodeTableId =
    Decode.map2 (\s t -> ( s, t ))
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "table" TableName.decode)
