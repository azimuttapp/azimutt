module Libs.Models.Color exposing (Color, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias Color =
    String


encode : Color -> Value
encode value =
    Encode.string value


decode : Decode.Decoder Color
decode =
    Decode.string
