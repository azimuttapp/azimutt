module Models.Project.ColumnRef exposing (ColumnRef, ColumnRefLike, decode, encode, fromString, show, toString)

import Conf
import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Encode as Encode
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)


type alias ColumnRef =
    { table : TableId, column : ColumnName }


type alias ColumnRefLike x =
    { x | table : TableId, column : ColumnName }


show : SchemaName -> ColumnRefLike x -> String
show defaultSchema { table, column } =
    TableId.show defaultSchema table |> ColumnName.withName column


toString : ColumnRef -> String
toString ref =
    TableId.toString ref.table ++ "." ++ ref.column


fromString : String -> ColumnRef
fromString id =
    case String.split "." id of
        schema :: table :: column :: [] ->
            { table = ( schema, table ), column = column }

        table :: column :: [] ->
            { table = ( Conf.schema.empty, table ), column = column }

        _ ->
            { table = ( Conf.schema.empty, id ), column = "" }


encode : ColumnRef -> Value
encode value =
    Encode.notNullObject
        [ ( "table", value.table |> TableId.encode )
        , ( "column", value.column |> ColumnName.encode )
        ]


decode : Decode.Decoder ColumnRef
decode =
    Decode.map2 ColumnRef
        (Decode.field "table" TableId.decode)
        (Decode.field "column" ColumnName.decode)
