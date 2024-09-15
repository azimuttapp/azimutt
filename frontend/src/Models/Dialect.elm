module Models.Dialect exposing (Dialect(..), decode, encode, export, fromString, toString)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode


type Dialect
    = AML
    | PostgreSQL
    | MySQL
    | JSON


export : List Dialect
export =
    [ AML, PostgreSQL, MySQL, JSON ]


toString : Dialect -> String
toString dialect =
    case dialect of
        AML ->
            "AML"

        PostgreSQL ->
            "PostgreSQL"

        MySQL ->
            "MySQL"

        JSON ->
            "JSON"


fromString : String -> Maybe Dialect
fromString dialect =
    case dialect of
        "AML" ->
            Just AML

        "PostgreSQL" ->
            Just PostgreSQL

        "MySQL" ->
            Just MySQL

        "JSON" ->
            Just JSON

        _ ->
            Nothing


encode : Dialect -> Value
encode value =
    value |> toString |> Encode.string


decode : Decode.Decoder Dialect
decode =
    Decode.string |> Decode.andThen (\v -> v |> fromString |> Decode.fromMaybe ("'" ++ v ++ "' is not a valid Dialect"))
