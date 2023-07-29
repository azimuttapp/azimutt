module Models.JsValue exposing (JsValue(..), decode, encode, format, toString)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Bool as Bool



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


format : JsValue -> String
format value =
    formatWithPrefix "  " "" value


formatWithPrefix : String -> String -> JsValue -> String
formatWithPrefix prefix nesting value =
    case value of
        Array values ->
            "[" ++ (values |> List.map (\v -> "\n" ++ nesting ++ prefix ++ formatWithPrefix prefix (nesting ++ prefix) v) |> String.join ",") ++ "\n" ++ nesting ++ "]"

        Object values ->
            "{" ++ (values |> Dict.toList |> List.map (\( k, v ) -> "\n" ++ nesting ++ prefix ++ k ++ ": " ++ formatWithPrefix prefix (nesting ++ prefix) v) |> String.join ",") ++ "\n" ++ nesting ++ "}"

        _ ->
            toString value


toString : JsValue -> String
toString value =
    case value of
        String v ->
            v |> String.replace "\n" "\\n"

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
