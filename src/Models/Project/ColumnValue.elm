module Models.Project.ColumnValue exposing (ColumnValue, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias ColumnValue =
    String


merge : ColumnValue -> ColumnValue -> ColumnValue
merge v1 _ =
    v1


encode : ColumnValue -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ColumnValue
decode =
    Decode.string
