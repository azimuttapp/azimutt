module Libs.Models.FileUrl exposing (FileUrl, decode, encode, filename)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.List as List
import Libs.Models.FileName exposing (FileName)


type alias FileUrl =
    String


filename : FileUrl -> FileName
filename url =
    url
        |> String.split "?"
        |> List.filter (\p -> not (p == ""))
        |> List.head
        |> Maybe.withDefault ""
        |> String.split "#"
        |> List.filter (\p -> not (p == ""))
        |> List.head
        |> Maybe.withDefault ""
        |> String.split "/"
        |> List.filter (\p -> not (p == ""))
        |> List.last
        |> Maybe.withDefault ""


encode : FileUrl -> Value
encode value =
    Encode.string value


decode : Decode.Decoder FileUrl
decode =
    Decode.string
