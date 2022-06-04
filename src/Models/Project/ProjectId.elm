module Models.Project.ProjectId exposing (ProjectId, decode, encode, isSample)

import Json.Decode as Decode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)


type alias ProjectId =
    Uuid


isSample : ProjectId -> Bool
isSample id =
    id |> String.startsWith "0000"


encode : ProjectId -> Value
encode value =
    Uuid.encode value


decode : Decode.Decoder ProjectId
decode =
    Uuid.decode
