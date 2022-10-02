module Libs.Models.Slug exposing (Slug, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias Slug =
    String


encode : Slug -> Value
encode value =
    Encode.string value


decode : Decode.Decoder Slug
decode =
    Decode.string
