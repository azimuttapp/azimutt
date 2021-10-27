module Models.Project.ColumnName exposing (ColumnName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias ColumnName =
    -- needs to be comparable to be in Dict key
    String


encode : ColumnName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ColumnName
decode =
    Decode.string
