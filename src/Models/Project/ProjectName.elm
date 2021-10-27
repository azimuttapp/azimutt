module Models.Project.ProjectName exposing (ProjectName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias ProjectName =
    String


encode : ProjectName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ProjectName
decode =
    Decode.string
