module Libs.Models.FileModified exposing (FileModified, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Time as Time
import Time


type alias FileModified =
    Time.Posix


encode : FileModified -> Value
encode value =
    Time.encode value


decode : Decode.Decoder FileModified
decode =
    Time.decode
