module Libs.Models.ZoomLevel exposing (ZoomLevel, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias ZoomLevel =
    Float


encode : ZoomLevel -> Value
encode value =
    Encode.float value


decode : Decode.Decoder ZoomLevel
decode =
    Decode.float
