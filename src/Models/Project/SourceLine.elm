module Models.Project.SourceLine exposing (SourceLine, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias SourceLine =
    String


encode : SourceLine -> Value
encode value =
    Encode.string value


decode : Decode.Decoder SourceLine
decode =
    Decode.string
