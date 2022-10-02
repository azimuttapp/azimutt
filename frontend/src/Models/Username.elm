module Models.Username exposing (Username, decode, encode)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode


type alias Username =
    String


encode : Username -> Value
encode value =
    Encode.string value


decode : Decode.Decoder Username
decode =
    Decode.string
