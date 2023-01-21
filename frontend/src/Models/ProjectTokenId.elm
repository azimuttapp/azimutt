module Models.ProjectTokenId exposing (ProjectTokenId, decode, encode)

import Json.Decode as Decode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)


type alias ProjectTokenId =
    Uuid


encode : ProjectTokenId -> Value
encode value =
    Uuid.encode value


decode : Decode.Decoder ProjectTokenId
decode =
    Uuid.decode
