module Models.Project.CustomTypeName exposing (CustomTypeName, decode, encode)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode


type alias CustomTypeName =
    String


encode : CustomTypeName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder CustomTypeName
decode =
    Decode.string
