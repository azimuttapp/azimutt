module Models.Project.ColumnType exposing (ColumnType, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias ColumnType =
    String


encode : ColumnType -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ColumnType
decode =
    Decode.string
