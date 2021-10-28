module Models.Project.ColumnRef exposing (ColumnRef, decode, encode, show)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Encode as E
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.TableId as TableId exposing (TableId)


type alias ColumnRef =
    { table : TableId, column : ColumnName }


show : ColumnRef -> String
show ref =
    TableId.show ref.table ++ "." ++ ref.column


encode : ColumnRef -> Value
encode value =
    E.object
        [ ( "table", value.table |> TableId.encode )
        , ( "column", value.column |> ColumnName.encode )
        ]


decode : Decode.Decoder ColumnRef
decode =
    Decode.map2 ColumnRef
        (Decode.field "table" TableId.decode)
        (Decode.field "column" ColumnName.decode)
