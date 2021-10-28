module Libs.Models.FileUrl exposing (FileUrl, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias FileUrl =
    String


encode : FileUrl -> Value
encode value =
    Encode.string value


decode : Decode.Decoder FileUrl
decode =
    Decode.string
