module Models.Project.ColumnRef exposing (ColumnRef, decode, encode, fromString, show, toString)

import Conf
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


toString : ColumnRef -> String
toString ref =
    (ref.table |> Tuple.first) ++ "." ++ (ref.table |> Tuple.second) ++ "." ++ ref.column


fromString : String -> ColumnRef
fromString id =
    case String.split "." id of
        schema :: table :: column :: [] ->
            { table = ( schema, table ), column = column }

        table :: column :: [] ->
            { table = ( Conf.schema.default, table ), column = column }

        _ ->
            { table = ( Conf.schema.default, id ), column = "" }


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
