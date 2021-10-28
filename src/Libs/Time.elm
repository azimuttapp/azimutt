module Libs.Time exposing (decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Time


encode : Time.Posix -> Value
encode value =
    value |> Time.posixToMillis |> Encode.int


decode : Decode.Decoder Time.Posix
decode =
    Decode.int |> Decode.map Time.millisToPosix
