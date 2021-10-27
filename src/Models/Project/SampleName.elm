module Models.Project.SampleName exposing (SampleName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias SampleName =
    String


encode : SampleName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder SampleName
decode =
    Decode.string
