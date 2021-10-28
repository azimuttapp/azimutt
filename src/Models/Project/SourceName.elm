module Models.Project.SourceName exposing (SourceName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias SourceName =
    String


encode : SourceName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder SourceName
decode =
    Decode.string
