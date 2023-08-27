module Models.Project.RowPrimaryKey exposing (RowPrimaryKey, decode, encode)

import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel exposing (Nel)
import Models.Project.RowValue as RowValue exposing (RowValue)


type alias RowPrimaryKey =
    Nel RowValue


encode : RowPrimaryKey -> Value
encode value =
    value |> Encode.nel RowValue.encode


decode : Decoder RowPrimaryKey
decode =
    Decode.nel RowValue.decode
