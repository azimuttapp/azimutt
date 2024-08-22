module Models.Project.RowPrimaryKey exposing (RowPrimaryKey, decode, encode, extractLabel, labelColName)

import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel as Nel exposing (Nel)
import Models.DbValue exposing (DbValue)
import Models.Project.RowValue as RowValue exposing (RowValue)


type alias RowPrimaryKey =
    Nel RowValue


labelColName : String
labelColName =
    -- needs to be very specific to avoid conflicts
    "azimutt_label"


extractLabel : RowPrimaryKey -> ( RowPrimaryKey, Maybe DbValue )
extractLabel values =
    let
        ( alt, pk ) =
            values |> Nel.partition (\v -> v.column.head == labelColName)
    in
    (pk |> Nel.fromList)
        |> Maybe.map (\cols -> ( cols, alt |> List.head |> Maybe.map .value ))
        |> Maybe.withDefault ( values, Nothing )


encode : RowPrimaryKey -> Value
encode value =
    value |> Encode.nel RowValue.encode


decode : Decoder RowPrimaryKey
decode =
    Decode.nel RowValue.decode
