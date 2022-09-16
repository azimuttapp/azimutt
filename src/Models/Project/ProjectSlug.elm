module Models.Project.ProjectSlug exposing (ProjectSlug, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Models.Slug as Slug exposing (Slug)


type alias ProjectSlug =
    Slug


encode : ProjectSlug -> Value
encode value =
    Slug.encode value


decode : Decode.Decoder ProjectSlug
decode =
    Slug.decode
