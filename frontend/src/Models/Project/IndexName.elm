module Models.Project.IndexName exposing (IndexName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias IndexName =
    String


encode : IndexName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder IndexName
decode =
    Decode.string
