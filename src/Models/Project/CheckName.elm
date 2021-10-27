module Models.Project.CheckName exposing (CheckName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias CheckName =
    String


encode : CheckName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder CheckName
decode =
    Decode.string
