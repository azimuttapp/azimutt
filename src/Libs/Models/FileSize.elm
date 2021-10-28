module Libs.Models.FileSize exposing (FileSize, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias FileSize =
    Int


encode : FileSize -> Value
encode value =
    Encode.int value


decode : Decode.Decoder FileSize
decode =
    Decode.int
