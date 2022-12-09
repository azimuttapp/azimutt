module Models.HerokuId exposing (HerokuId, encode)

import Json.Encode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)


type alias HerokuId =
    Uuid


encode : HerokuId -> Value
encode value =
    Uuid.encode value
