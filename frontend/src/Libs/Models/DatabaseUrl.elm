module Libs.Models.DatabaseUrl exposing (DatabaseUrl, databaseName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.List as List
import Libs.Maybe as Maybe


type alias DatabaseUrl =
    String


databaseName : DatabaseUrl -> String
databaseName url =
    if url |> String.toLower |> String.contains "Database=" then
        url |> String.split ";" |> List.find (\p -> p |> String.toLower |> String.startsWith "Database") |> Maybe.mapOrElse (\p -> p |> String.split "=" |> List.get 1 |> Maybe.withDefault url) url

    else
        url |> String.split "/" |> List.reverse |> List.head |> Maybe.andThen (String.split "?" >> List.head) |> Maybe.andThen (String.split "@" >> List.last) |> Maybe.withDefault url


encode : DatabaseUrl -> Value
encode value =
    Encode.string value


decode : Decode.Decoder DatabaseUrl
decode =
    Decode.string
