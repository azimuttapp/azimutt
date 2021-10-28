module Libs.Models.FileLineIndex exposing (FileLineIndex, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias FileLineIndex =
    Int


encode : FileLineIndex -> Value
encode value =
    Encode.int value


decode : Decode.Decoder FileLineIndex
decode =
    Decode.int
