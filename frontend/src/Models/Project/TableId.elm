module Models.Project.TableId exposing (TableId, TableIdStr, decode, decodeWith, encode, fromHtmlId, fromString, name, parse, parseWith, schema, show, toHtmlId, toString)

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


type alias TableIdStr =
    String


schema : TableId -> SchemaName
schema ( s, _ ) =
    s


name : TableId -> TableName
name ( _, t ) =
    t


toHtmlId : TableId -> HtmlId
toHtmlId ( s, t ) =
    "table-" ++ s ++ "-" ++ (t |> HtmlId.encode)


fromHtmlId : HtmlId -> Maybe TableId
fromHtmlId id =
    case String.split "-" id of
        "table" :: s :: t :: [] ->
            Just ( s, t |> HtmlId.decode )

        _ ->
            Nothing


toString : TableId -> String
toString ( s, t ) =
    s ++ "." ++ t


fromString : String -> Maybe TableId
fromString id =
    case String.split "." id of
        s :: t :: [] ->
            Just ( s, t )

        _ ->
            Nothing


show : SchemaName -> TableId -> String
show defaultSchema ( s, t ) =
    if s == Conf.schema.empty || s == defaultSchema then
        t

    else
        s ++ "." ++ t


parse : String -> TableId
parse tableId =
    parseWith Conf.schema.empty tableId


parseWith : SchemaName -> String -> TableId
parseWith defaultSchema tableId =
    case tableId |> String.split "." of
        s :: t :: [] ->
            ( s, t )

        _ ->
            ( defaultSchema, tableId )


encode : TableId -> Value
encode value =
    Encode.string (toString value)


decode : Decode.Decoder TableId
decode =
    Decode.string |> Decode.andThen (\str -> str |> fromString |> Maybe.mapOrElse Decode.succeed (Decode.fail ("Invalid TableId '" ++ str ++ "'")))


decodeWith : SchemaName -> Decode.Decoder TableId
decodeWith defaultSchema =
    Decode.string |> Decode.map (\str -> str |> fromString |> Maybe.withDefault ( defaultSchema, str ))
