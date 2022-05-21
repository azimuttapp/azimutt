module Models.Project.ProjectId exposing (ProjectId, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Models exposing (Uuid)


type alias ProjectId =
    Uuid


encode : ProjectId -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ProjectId
decode =
    Decode.string
