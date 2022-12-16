module Models.HerokuId exposing (HerokuId, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)


type alias HerokuId =
    Uuid


encode : HerokuId -> Value
encode value =
    Uuid.encode value


decode : Decode.Decoder HerokuId
decode =
    Uuid.decode
