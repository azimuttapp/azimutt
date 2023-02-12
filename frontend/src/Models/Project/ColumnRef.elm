module Models.Project.ColumnRef exposing (ColumnRef, ColumnRefLike, decode, encode, from, fromString, show, toString)

import Conf
import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Encode as Encode
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)


type alias ColumnRef =
    { table : TableId, column : ColumnPath }


type alias ColumnRefLike x =
    { x | table : TableId, column : ColumnPath }


from : { t | id : TableId } -> { c | path : ColumnPath } -> ColumnRef
from table column =
    { table = table.id, column = column.path }


show : SchemaName -> ColumnRefLike x -> String
show defaultSchema { table, column } =
    TableId.show defaultSchema table |> ColumnPath.withName column


toString : ColumnRef -> String
toString ref =
    TableId.toString ref.table ++ "." ++ ColumnPath.toString ref.column


fromString : String -> ColumnRef
fromString id =
    case String.split "." id of
        schema :: table :: column :: [] ->
            { table = ( schema, table ), column = ColumnPath.fromString column }

        table :: column :: [] ->
            { table = ( Conf.schema.empty, table ), column = ColumnPath.fromString column }

        _ ->
            { table = ( Conf.schema.empty, id ), column = ColumnPath.fromString "" }


encode : ColumnRef -> Value
encode value =
    Encode.notNullObject
        [ ( "table", value.table |> TableId.encode )
        , ( "column", value.column |> ColumnPath.encode )
        ]


decode : Decode.Decoder ColumnRef
decode =
    Decode.map2 ColumnRef
        (Decode.field "table" TableId.decode)
        (Decode.field "column" ColumnPath.decode)
