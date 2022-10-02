module Models.UserId exposing (UserId, decode, encode)

import Json.Decode as Decode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)


type alias UserId =
    Uuid


encode : UserId -> Value
encode value =
    Uuid.encode value


decode : Decode.Decoder UserId
decode =
    Uuid.decode
