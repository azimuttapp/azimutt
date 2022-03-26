module Models.Project.TableId exposing (TableId, decode, encode, fromHtmlId, fromString, parse, show, toHtmlId, toString)

import Conf
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Models.HtmlId as HtmlId exposing (HtmlId)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableName exposing (TableName)


type alias TableId =
    -- needs to be comparable to be in Dict key
    ( SchemaName, TableName )


toHtmlId : TableId -> HtmlId
toHtmlId ( schema, table ) =
    "table-" ++ schema ++ "-" ++ (table |> HtmlId.encode)


fromHtmlId : HtmlId -> TableId
fromHtmlId id =
    case String.split "-" id of
        "table" :: schema :: table :: [] ->
            ( schema, table |> HtmlId.decode )

        _ ->
            ( Conf.schema.default, id )


toString : TableId -> String
toString ( schema, table ) =
    schema ++ "." ++ table


fromString : String -> TableId
fromString id =
    case String.split "." id of
        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( Conf.schema.default, id )


show : TableId -> String
show ( schema, table ) =
    if schema == Conf.schema.default then
        table

    else
        schema ++ "." ++ table


parse : String -> TableId
parse tableId =
    case tableId |> String.split "." of
        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( Conf.schema.default, tableId )


encode : TableId -> Value
encode value =
    Encode.string (toString value)


decode : Decode.Decoder TableId
decode =
    Decode.string |> Decode.map fromString
