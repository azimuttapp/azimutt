module Models.Project.ProjectId exposing (ProjectId, decode, encode, isSample)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Models exposing (Uuid)


type alias ProjectId =
    Uuid


isSample : ProjectId -> Bool
isSample id =
    id |> String.startsWith "0000"


encode : ProjectId -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ProjectId
decode =
    Decode.string
