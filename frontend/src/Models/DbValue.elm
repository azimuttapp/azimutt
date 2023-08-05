module Models.DbValue exposing (DbValue(..), compare, decode, encode, fromString, isArray, isObject, toJson, toString, view, viewRaw)

import Dict exposing (Dict)
import Html exposing (Html, pre, span, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Order exposing (compareBool, compareDict, compareList)
import Models.Project.ColumnType as ColumnType exposing (ColumnType)


type DbValue
    = DbString String
    | DbInt Int
    | DbFloat Float
    | DbBool Bool
    | DbNull
    | DbArray (List DbValue)
    | DbObject (Dict String DbValue)


isArray : DbValue -> Bool
isArray value =
    case value of
        DbArray _ ->
            True

        _ ->
            False


isObject : DbValue -> Bool
isObject value =
    case value of
        DbObject _ ->
            True

        _ ->
            False


fromString : ColumnType -> String -> DbValue
fromString kind value =
    case ColumnType.parse kind of
        ColumnType.Int ->
            value |> String.toInt |> Maybe.map DbInt |> Maybe.withDefault (DbString value)

        ColumnType.Float ->
            value |> String.toFloat |> Maybe.map DbFloat |> Maybe.withDefault (DbString value)

        ColumnType.Bool ->
            value |> Bool.fromString |> Maybe.map DbBool |> Maybe.withDefault (DbString value)

        _ ->
            if value == "null" then
                DbNull

            else
                DbString value


toString : DbValue -> String
toString value =
    case value of
        DbString v ->
            v

        DbInt v ->
            String.fromInt v

        DbFloat v ->
            String.fromFloat v

        DbBool v ->
            Bool.toString v

        DbNull ->
            "null"

        DbArray values ->
            "[" ++ (values |> List.map toString |> String.join ", ") ++ "]"

        DbObject values ->
            "{" ++ (values |> Dict.toList |> List.map (\( k, v ) -> k ++ ": " ++ toString v) |> String.join ", ") ++ "}"


toJson : DbValue -> String
toJson value =
    case value of
        DbString v ->
            "\"" ++ (v |> String.replace "\n" "\\n") ++ "\""

        DbInt v ->
            String.fromInt v

        DbFloat v ->
            String.fromFloat v

        DbBool v ->
            Bool.cond v "true" "false"

        DbNull ->
            "null"

        DbArray values ->
            "[" ++ (values |> List.map toJson |> String.join ", ") ++ "]"

        DbObject values ->
            "{" ++ (values |> Dict.toList |> List.map (\( k, v ) -> k ++ ": " ++ toJson v) |> String.join ", ") ++ "}"


compare : DbValue -> DbValue -> Order
compare value1 value2 =
    case ( value1, value2 ) of
        ( DbString v1, DbString v2 ) ->
            Basics.compare v1 v2

        ( DbInt v1, DbInt v2 ) ->
            Basics.compare v1 v2

        ( DbFloat v1, DbFloat v2 ) ->
            Basics.compare v1 v2

        ( DbBool v1, DbBool v2 ) ->
            compareBool v1 v2

        ( DbArray v1, DbArray v2 ) ->
            compareList compare v1 v2

        ( DbObject v1, DbObject v2 ) ->
            compareDict compare v1 v2

        _ ->
            EQ


view : Maybe DbValue -> Html msg
view value =
    case value of
        Just v ->
            viewDbValue v

        Nothing ->
            text ""


viewDbValue : DbValue -> Html msg
viewDbValue value =
    case value of
        DbString str ->
            text str

        DbInt i ->
            text (String.fromInt i)

        DbFloat f ->
            text (String.fromFloat f)

        DbBool b ->
            text (Bool.toString b)

        DbNull ->
            span [ class "opacity-50 italic" ] [ text "null" ]

        DbArray a ->
            span [] (text "[" :: (a |> List.map viewDbValue |> List.intersperse (text ", ")) |> List.add (text "]"))

        DbObject o ->
            span [] (text "{" :: (o |> Dict.toList |> List.map (\( k, v ) -> span [] [ text (k ++ ": "), viewDbValue v ]) |> List.intersperse (text ", ")) |> List.add (text "}"))


viewRaw : Maybe DbValue -> Html msg
viewRaw value =
    pre [ class "text-xs" ] [ text (value |> Maybe.mapOrElse (format "  " "") "") ]


format : String -> String -> DbValue -> String
format prefix nesting value =
    -- like `toString` but with line return & indentation formatting on Array & Object
    case value of
        DbArray values ->
            "[" ++ (values |> List.map (\v -> "\n" ++ nesting ++ prefix ++ format prefix (nesting ++ prefix) v) |> String.join ",") ++ "\n" ++ nesting ++ "]"

        DbObject values ->
            "{" ++ (values |> Dict.toList |> List.map (\( k, v ) -> "\n" ++ nesting ++ prefix ++ k ++ ": " ++ format prefix (nesting ++ prefix) v) |> String.join ",") ++ "\n" ++ nesting ++ "}"

        _ ->
            toJson value


encode : DbValue -> Value
encode value =
    case value of
        DbString v ->
            Encode.string v

        DbInt v ->
            Encode.int v

        DbFloat v ->
            Encode.float v

        DbBool v ->
            Encode.bool v

        DbNull ->
            Encode.null

        DbArray values ->
            values |> Encode.list encode

        DbObject values ->
            values |> Encode.dict identity encode


decode : Decoder DbValue
decode =
    Decode.oneOf
        [ Decode.string |> Decode.map DbString
        , Decode.int |> Decode.map DbInt
        , Decode.float |> Decode.map DbFloat
        , Decode.bool |> Decode.map DbBool
        , Decode.null () |> Decode.map (\_ -> DbNull)
        , Decode.list (Decode.lazy (\_ -> decode)) |> Decode.map DbArray
        , Decode.dict (Decode.lazy (\_ -> decode)) |> Decode.map DbObject
        ]
