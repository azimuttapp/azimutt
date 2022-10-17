module Models.Project.ProjectId exposing (ProjectId, decode, encode, isSample, zero)

import Json.Decode as Decode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)


type alias ProjectId =
    Uuid


zero : ProjectId
zero =
    Uuid.zero


isSample : ProjectId -> Bool
isSample id =
    String.startsWith "0000" id && not (String.endsWith "0000" id)


encode : ProjectId -> Value
encode value =
    Uuid.encode value


decode : Decode.Decoder ProjectId
decode =
    Uuid.decode
