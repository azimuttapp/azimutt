module Models.Project.RowPrimaryKey exposing (RowPrimaryKey, altColName, decode, encode, extractAlt)

import Dict exposing (Dict)
import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
import Libs.Nel as Nel exposing (Nel)
import Models.DbValue exposing (DbValue)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.RowValue as RowValue exposing (RowValue)


type alias RowPrimaryKey =
    Nel RowValue


altColName : String
altColName =
    "alt"


extractAlt : RowPrimaryKey -> ( RowPrimaryKey, Maybe DbValue )
extractAlt values =
    let
        ( alt, pk ) =
            values |> Nel.partition (\v -> v.column.head == altColName)
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
