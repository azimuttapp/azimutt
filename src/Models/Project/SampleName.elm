module Models.Project.SampleName exposing (SampleKey, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias SampleKey =
    String


encode : SampleKey -> Value
encode value =
    Encode.string value


decode : Decode.Decoder SampleKey
decode =
    Decode.string
