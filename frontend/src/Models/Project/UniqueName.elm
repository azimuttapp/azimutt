module Models.Project.UniqueName exposing (UniqueName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias UniqueName =
    String


encode : UniqueName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder UniqueName
decode =
    Decode.string
