module Models.Project.TableId exposing (TableId, TableIdStr, decode, decodeWith, dictGetI, encode, eqI, fromHtmlId, fromString, name, parse, parseWith, schema, show, toHtmlId, toLower, toString)

import Conf
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Dict as Dict
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


toLower : TableId -> TableId
toLower ( s, t ) =
    ( String.toLower s, String.toLower t )


eqI : TableId -> TableId -> Bool
eqI id1 id2 =
    toLower id1 == toLower id2


dictGetI : TableId -> Dict TableId a -> Maybe a
dictGetI id dict =
    (dict |> Dict.get id)
        |> Maybe.orElse (id |> toLower |> (\lowerId -> dict |> Dict.find (\k _ -> toLower k == lowerId)))
        -- TODO: try with `defaultSchema` if `schema id == Conf.schema.empty`?
        |> Maybe.orElse (id |> name |> String.toLower |> (\lowerName -> dict |> Dict.find (\k _ -> (k |> name |> String.toLower) == lowerName)))


show : SchemaName -> TableId -> String
show defaultSchema ( s, t ) =
    if s == Conf.schema.empty || s == defaultSchema then
        t

    else
        s ++ "." ++ t


toHtmlId : TableId -> HtmlId
toHtmlId ( s, t ) =
    -- `~` is used to serialize args to String (cf frontend/src/PagesComponents/Organization_/Project_/Views/Erd.elm:86)
    -- `#` is used in Oracle user (used as table schema ^^)
    "table|" ++ s ++ "|" ++ (t |> HtmlId.encode)


fromHtmlId : HtmlId -> Maybe TableId
fromHtmlId id =
    case String.split "|" id of
        "table" :: s :: t :: [] ->
            Just ( s, t |> HtmlId.decode )

        _ ->
            Nothing


toString : TableId -> String
toString ( s, t ) =
    s ++ "." ++ t


fromString : String -> Maybe TableId
fromString tableId =
    -- TableName may have "." inside :/
    case tableId |> String.split "." of
        s :: t :: rest ->
            Just ( s, (t :: rest) |> String.join "." )

        _ ->
            Nothing


parseWith : SchemaName -> String -> TableId
parseWith defaultSchema tableId =
    -- TableName may have "." inside :/
    case tableId |> String.split "." of
        s :: t :: rest ->
            ( s, (t :: rest) |> String.join "." )

        _ ->
            ( defaultSchema, tableId )


parse : String -> TableId
parse tableId =
    parseWith Conf.schema.empty tableId


encode : TableId -> Value
encode value =
    Encode.string (toString value)


decode : Decode.Decoder TableId
decode =
    Decode.string |> Decode.andThen (\str -> str |> fromString |> Maybe.mapOrElse Decode.succeed (Decode.fail ("Invalid TableId '" ++ str ++ "'")))


decodeWith : SchemaName -> Decode.Decoder TableId
decodeWith defaultSchema =
    Decode.string |> Decode.map (\str -> str |> fromString |> Maybe.withDefault ( defaultSchema, str ))
