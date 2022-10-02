module Libs.Models.DatabaseUrl exposing (DatabaseUrl, databaseName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias DatabaseUrl =
    String


databaseName : DatabaseUrl -> String
databaseName url =
    url |> String.split "/" |> List.reverse |> List.head |> Maybe.withDefault url


encode : DatabaseUrl -> Value
encode value =
    Encode.string value


decode : Decode.Decoder DatabaseUrl
decode =
    Decode.string
