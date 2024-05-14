module Models.OpenAIKey exposing (OpenAIKey, decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias OpenAIKey =
    String


encode : OpenAIKey -> Encode.Value
encode =
    Encode.string


decode : Decoder OpenAIKey
decode =
    Decode.string
