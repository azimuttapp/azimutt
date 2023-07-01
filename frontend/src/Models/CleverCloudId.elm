module Models.CleverCloudId exposing (CleverCloudId, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)


type alias CleverCloudId =
    Uuid


encode : CleverCloudId -> Value
encode value =
    Uuid.encode value


decode : Decode.Decoder CleverCloudId
decode =
    Uuid.decode
