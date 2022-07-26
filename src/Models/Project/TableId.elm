module Models.Project.TableId exposing (TableId, decode, decodeWith, encode, fromHtmlId, fromString, parse, show, toHtmlId, toString)

import Conf
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId as HtmlId exposing (HtmlId)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableName exposing (TableName)


type alias TableId =
    -- needs to be comparable to be in Dict key
    ( SchemaName, TableName )


toHtmlId : TableId -> HtmlId
toHtmlId ( schema, table ) =
    "table-" ++ schema ++ "-" ++ (table |> HtmlId.encode)


fromHtmlId : HtmlId -> Maybe TableId
fromHtmlId id =
    case String.split "-" id of
        "table" :: schema :: table :: [] ->
            Just ( schema, table |> HtmlId.decode )

        _ ->
            Nothing


toString : TableId -> String
toString ( schema, table ) =
    schema ++ "." ++ table


fromString : String -> Maybe TableId
fromString id =
    case String.split "." id of
        schema :: table :: [] ->
            Just ( schema, table )

        _ ->
            Nothing


show : SchemaName -> TableId -> String
show defaultSchema ( schema, table ) =
    if schema == Conf.schema.empty || schema == defaultSchema then
        table

    else
        schema ++ "." ++ table


parse : String -> TableId
parse tableId =
    case tableId |> String.split "." of
        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( Conf.schema.empty, tableId )


encode : TableId -> Value
encode value =
    Encode.string (toString value)


decode : Decode.Decoder TableId
decode =
    Decode.string |> Decode.andThen (\str -> str |> fromString |> Maybe.mapOrElse Decode.succeed (Decode.fail ("Invalid TableId '" ++ str ++ "'")))


decodeWith : SchemaName -> Decode.Decoder TableId
decodeWith defaultSchema =
    Decode.string |> Decode.map (\str -> str |> fromString |> Maybe.withDefault ( defaultSchema, str ))
