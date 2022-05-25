module Libs.Models.Website exposing (Website, decode, encode, isValid)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode


type alias Website =
    String


isValid : String -> Bool
isValid value =
    value |> String.startsWith "http"


encode : Website -> Value
encode value =
    Encode.string value


decode : Decode.Decoder Website
decode =
    Decode.string
        |> Decode.andThen
            (\v ->
                if isValid v then
                    Decode.succeed v

                else
                    Decode.fail ("'" ++ v ++ "' is not a valid Website")
            )
