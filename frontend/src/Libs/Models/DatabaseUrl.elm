module Libs.Models.DatabaseUrl exposing (DatabaseUrl, databaseName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.List as List
import Libs.Maybe as Maybe


type alias DatabaseUrl =
    String


databaseName : DatabaseUrl -> String
databaseName url =
    if url |> String.contains "Database=" then
        url |> String.split ";" |> List.find (\p -> p |> String.startsWith "Database") |> Maybe.mapOrElse (\p -> p |> String.replace "Database=" "") url

    else
        url |> String.split "/" |> List.reverse |> List.head |> Maybe.withDefault url


encode : DatabaseUrl -> Value
encode value =
    Encode.string value


decode : Decode.Decoder DatabaseUrl
decode =
    Decode.string
