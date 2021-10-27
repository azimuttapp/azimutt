module Models.Project.PrimaryKeyName exposing (PrimaryKeyName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias PrimaryKeyName =
    String


encode : PrimaryKeyName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder PrimaryKeyName
decode =
    Decode.string
