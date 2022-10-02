module Models.Project.ProjectEncodingVersion exposing (ProjectEncodingVersion, current, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode



-- compatibility version for Project JSON, when you have breaking change, increment it and handle needed migrations


type alias ProjectEncodingVersion =
    Int


current : ProjectEncodingVersion
current =
    2


decode : Decode.Decoder Int
decode =
    Decode.int


encode : ProjectEncodingVersion -> Encode.Value
encode =
    Encode.int
