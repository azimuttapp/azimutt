module Models.Project.ProjectId exposing (ProjectId, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Models exposing (UID)


type alias ProjectId =
    UID


encode : ProjectId -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ProjectId
decode =
    Decode.string
