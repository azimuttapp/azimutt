module Models.UserSlug exposing (UserSlug, decode)

import Json.Decode as Decode
import Libs.Models.Slug as Slug exposing (Slug)


type alias UserSlug =
    Slug


decode : Decode.Decoder UserSlug
decode =
    Slug.decode
