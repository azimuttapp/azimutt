module Libs.Models.Uuid exposing (Uuid, decode, encode)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode


type alias Uuid =
    String


encode : Uuid -> Value
encode value =
    Encode.string value


decode : Decode.Decoder Uuid
decode =
    Decode.string
