module Models.Project.ColumnType exposing (ColumnType, decode, encode, label)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.String as String
import Models.Project.SchemaName exposing (SchemaName)


type alias ColumnType =
    String


label : SchemaName -> ColumnType -> String
label defaultSchema kind =
    kind |> String.stripLeft (defaultSchema ++ ".")


encode : ColumnType -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ColumnType
decode =
    Decode.string
