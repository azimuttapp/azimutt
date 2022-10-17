module Models.OrganizationName exposing (OrganizationName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias OrganizationName =
    String


encode : OrganizationName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder OrganizationName
decode =
    Decode.string
