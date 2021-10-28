module Libs.Models.FileName exposing (FileName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias FileName =
    String


encode : FileName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder FileName
decode =
    Decode.string
