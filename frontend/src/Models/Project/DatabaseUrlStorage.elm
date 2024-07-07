module Models.Project.DatabaseUrlStorage exposing (DatabaseUrlStorage(..), all, decode, encode, fromString, toString)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode


type DatabaseUrlStorage
    = Memory
    | Browser
    | Project


all : List DatabaseUrlStorage
all =
    [ Memory, Browser, Project ]


toString : DatabaseUrlStorage -> String
toString kind =
    case kind of
        Memory ->
            "memory"

        Browser ->
            "browser"

        Project ->
            "project"


fromString : String -> Maybe DatabaseUrlStorage
fromString kind =
    case kind of
        "memory" ->
            Just Memory

        "browser" ->
            Just Browser

        "project" ->
            Just Project

        _ ->
            Nothing


encode : DatabaseUrlStorage -> Value
encode value =
    value |> toString |> Encode.string


decode : Decoder DatabaseUrlStorage
decode =
    Decode.string |> Decode.andThen (\v -> v |> fromString |> Decode.fromMaybe ("Unknown DatabaseUrlStorage:" ++ v))
