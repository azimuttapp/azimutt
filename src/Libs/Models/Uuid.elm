module Libs.Models.Uuid exposing (Uuid, decode, encode, isValid, random)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Random
import UUID


type alias Uuid =
    String


random : Random.Seed -> ( Uuid, Random.Seed )
random seed =
    seed |> Random.step UUID.generator |> Tuple.mapFirst UUID.toString


isValid : String -> Bool
isValid value =
    String.length value == 36


encode : Uuid -> Value
encode value =
    Encode.string value


decode : Decode.Decoder Uuid
decode =
    Decode.string
        |> Decode.andThen
            (\v ->
                if isValid v then
                    Decode.succeed v

                else
                    Decode.fail ("'" ++ v ++ "' is not a valid Uuid")
            )
