module Models.OrganizationId exposing (OrganizationId, encode)

import Json.Encode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)


type alias OrganizationId =
    Uuid


encode : OrganizationId -> Value
encode value =
    Uuid.encode value
