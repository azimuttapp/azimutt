module Models.Project.TableId exposing (TableId, asHtmlId, asString, parse, parseHtmlId, parseString, show)

import Conf exposing (conf)
import Libs.Models.HtmlId as HtmlId exposing (HtmlId)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableName exposing (TableName)


type alias TableId =
    -- needs to be comparable to be in Dict key
    ( SchemaName, TableName )


asHtmlId : TableId -> HtmlId
asHtmlId ( schema, table ) =
    "table-" ++ schema ++ "-" ++ (table |> HtmlId.encode)


parseHtmlId : HtmlId -> TableId
parseHtmlId id =
    case String.split "-" id of
        "table" :: schema :: table :: [] ->
            ( schema, table |> HtmlId.decode )

        _ ->
            ( conf.default.schema, id )


asString : TableId -> String
asString ( schema, table ) =
    schema ++ "." ++ table


parseString : String -> TableId
parseString id =
    case String.split "." id of
        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( conf.default.schema, id )


show : TableId -> String
show ( schema, table ) =
    if schema == conf.default.schema then
        table

    else
        schema ++ "." ++ table


parse : String -> TableId
parse tableId =
    case tableId |> String.split "." of
        table :: [] ->
            ( conf.default.schema, table )

        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( conf.default.schema, tableId )
