module Models.Project.RowValue exposing (RowValue, decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Models.DbValue as DbValue exposing (DbValue)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)


type alias RowValue =
    { column : ColumnPath, value : DbValue }


encode : RowValue -> Value
encode value =
    Encode.object
        [ ( "column", value.column |> ColumnPath.encode )
        , ( "value", value.value |> DbValue.encode )
        ]


decode : Decoder RowValue
decode =
    Decode.map2 RowValue
        (Decode.field "column" ColumnPath.decode)
        (Decode.field "value" DbValue.decode)
