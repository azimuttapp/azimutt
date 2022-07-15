module Models.Project.ProjectId exposing (ProjectId, decode, encode, isSample, random)

import Json.Decode as Decode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)
import Random


type alias ProjectId =
    Uuid


random : Random.Seed -> ( ProjectId, Random.Seed )
random seed =
    seed |> Uuid.random


isSample : ProjectId -> Bool
isSample id =
    id |> String.startsWith "0000"


encode : ProjectId -> Value
encode value =
    Uuid.encode value


decode : Decode.Decoder ProjectId
decode =
    Uuid.decode
