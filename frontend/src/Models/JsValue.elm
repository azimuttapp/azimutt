module Models.JsValue exposing (JsValue(..), decode, encode, isArray, isObject, toJson, toString, view, viewRaw)

import Dict exposing (Dict)
import Html exposing (Html, pre, span, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Bool as Bool
import Libs.List as List
import Libs.Maybe as Maybe



-- represent a JSON value
-- TODO: add tests


type JsValue
    = String String
    | Int Int
    | Float Float
    | Bool Bool
    | Null
    | Array (List JsValue)
    | Object (Dict String JsValue)


isArray : JsValue -> Bool
isArray value =
    case value of
        Array _ ->
            True

        _ ->
            False


isObject : JsValue -> Bool
isObject value =
    case value of
        Object _ ->
            True

        _ ->
            False


toString : JsValue -> String
toString value =
    case value of
        String v ->
            v

        Int v ->
            String.fromInt v

        Float v ->
            String.fromFloat v

        Bool v ->
            Bool.toString v

        Null ->
            "null"

        Array values ->
            "[" ++ (values |> List.map toString |> String.join ", ") ++ "]"

        Object values ->
            "{" ++ (values |> Dict.toList |> List.map (\( k, v ) -> k ++ ": " ++ toString v) |> String.join ", ") ++ "}"


toJson : JsValue -> String
toJson value =
    case value of
        String v ->
            "\"" ++ (v |> String.replace "\n" "\\n") ++ "\""

        Int v ->
            String.fromInt v

        Float v ->
            String.fromFloat v

        Bool v ->
            Bool.cond v "true" "false"

        Null ->
            "null"

        Array values ->
            "[" ++ (values |> List.map toJson |> String.join ", ") ++ "]"

        Object values ->
            "{" ++ (values |> Dict.toList |> List.map (\( k, v ) -> k ++ ": " ++ toJson v) |> String.join ", ") ++ "}"


view : Maybe JsValue -> Html msg
view value =
    case value of
        Just v ->
            viewJsValue v

        Nothing ->
            text ""


viewJsValue : JsValue -> Html msg
viewJsValue value =
    case value of
        String str ->
            text str

        Int i ->
            text (String.fromInt i)

        Float f ->
            text (String.fromFloat f)

        Bool b ->
            text (Bool.toString b)

        Null ->
            span [ class "opacity-50 italic" ] [ text "null" ]

        Array a ->
            span [] (text "[" :: (a |> List.map viewJsValue |> List.intersperse (text ", ")) |> List.add (text "]"))

        Object o ->
            span [] (text "{" :: (o |> Dict.toList |> List.map (\( k, v ) -> span [] [ text (k ++ ": "), viewJsValue v ]) |> List.intersperse (text ", ")) |> List.add (text "}"))


viewRaw : Maybe JsValue -> Html msg
viewRaw value =
    pre [ class "text-xs" ] [ text (value |> Maybe.mapOrElse (format "  " "") "") ]


format : String -> String -> JsValue -> String
format prefix nesting value =
    -- like `toString` but with line return & indentation formatting on Array & Object
    case value of
        Array values ->
            "[" ++ (values |> List.map (\v -> "\n" ++ nesting ++ prefix ++ format prefix (nesting ++ prefix) v) |> String.join ",") ++ "\n" ++ nesting ++ "]"

        Object values ->
            "{" ++ (values |> Dict.toList |> List.map (\( k, v ) -> "\n" ++ nesting ++ prefix ++ k ++ ": " ++ format prefix (nesting ++ prefix) v) |> String.join ",") ++ "\n" ++ nesting ++ "}"

        _ ->
            toJson value


encode : JsValue -> Value
encode value =
    case value of
        String v ->
            Encode.string v

        Int v ->
            Encode.int v

        Float v ->
            Encode.float v

        Bool v ->
            Encode.bool v

        Null ->
            Encode.null

        Array values ->
            values |> Encode.list encode

        Object values ->
            values |> Encode.dict identity encode


decode : Decoder JsValue
decode =
    Decode.oneOf
        [ Decode.string |> Decode.map String
        , Decode.int |> Decode.map Int
        , Decode.float |> Decode.map Float
        , Decode.bool |> Decode.map Bool
        , Decode.null () |> Decode.map (\_ -> Null)
        , Decode.list (Decode.lazy (\_ -> decode)) |> Decode.map Array
        , Decode.dict (Decode.lazy (\_ -> decode)) |> Decode.map Object
        ]
