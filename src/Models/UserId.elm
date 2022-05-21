module Models.UserId exposing (UserId, decode, encode)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Libs.Models exposing (Uuid)


type alias UserId =
    Uuid


encode : UserId -> Value
encode value =
    Encode.string value


decode : Decode.Decoder UserId
decode =
    Decode.string
