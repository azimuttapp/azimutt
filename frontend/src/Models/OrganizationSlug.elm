module Models.OrganizationSlug exposing (OrganizationSlug, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Models.Slug as Slug exposing (Slug)


type alias OrganizationSlug =
    Slug


encode : OrganizationSlug -> Value
encode value =
    Slug.encode value


decode : Decode.Decoder OrganizationSlug
decode =
    Slug.decode
