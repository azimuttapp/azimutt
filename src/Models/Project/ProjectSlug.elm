module Models.Project.ProjectSlug exposing (ProjectSlug, decode, encode, zero)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Models.Slug as Slug exposing (Slug)
import Libs.Models.Uuid as Uuid


type alias ProjectSlug =
    Slug


zero : ProjectSlug
zero =
    Uuid.zero


encode : ProjectSlug -> Value
encode value =
    Slug.encode value


decode : Decode.Decoder ProjectSlug
decode =
    Slug.decode
