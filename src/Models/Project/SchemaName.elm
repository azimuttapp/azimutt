module Models.Project.SchemaName exposing (SchemaName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias SchemaName =
    -- needs to be comparable to have TableId in Dict key
    String


encode : SchemaName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder SchemaName
decode =
    Decode.string
