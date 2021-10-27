module Models.Project.ColumnValue exposing (ColumnValue, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias ColumnValue =
    String


encode : ColumnValue -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ColumnValue
decode =
    Decode.string
