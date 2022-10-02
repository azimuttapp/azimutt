module Models.Project.RelationName exposing (RelationName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias RelationName =
    String


encode : RelationName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder RelationName
decode =
    Decode.string
