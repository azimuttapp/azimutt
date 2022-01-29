module Libs.Models.FileUpdatedAt exposing (FileUpdatedAt, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Time as Time
import Time


type alias FileUpdatedAt =
    Time.Posix


encode : FileUpdatedAt -> Value
encode value =
    Time.encode value


decode : Decode.Decoder FileUpdatedAt
decode =
    Time.decode
