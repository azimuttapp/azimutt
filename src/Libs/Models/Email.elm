module Libs.Models.Email exposing (Email, decode, encode, isValid)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Libs.Regex as Regex


type alias Email =
    String


isValid : String -> Bool
isValid value =
    value |> Regex.match "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"


encode : Email -> Value
encode value =
    Encode.string value


decode : Decode.Decoder Email
decode =
    Decode.string
        |> Decode.andThen
            (\v ->
                if isValid v then
                    Decode.succeed v

                else
                    Decode.fail ("'" ++ v ++ "' is not a valid Email")
            )
