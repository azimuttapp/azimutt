module Models.Project.DatabaseUrlStorage exposing (DatabaseUrlStorage(..), all, decode, default, encode, explain, fromString, toString)

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


default : DatabaseUrlStorage
default =
    Browser


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


explain : DatabaseUrlStorage -> String
explain kind =
    case kind of
        Memory ->
            "Saved in JavaScript memory, you will have to fill it when you refresh the page."

        Browser ->
            "Saved encrypted in your browser, project collaborators will need fill it if they need it."

        Project ->
            "Saved in the project, it will be available to anyone having access to this project."


encode : DatabaseUrlStorage -> Value
encode value =
    value |> toString |> Encode.string


decode : Decoder DatabaseUrlStorage
decode =
    Decode.string |> Decode.andThen (\v -> v |> fromString |> Decode.fromMaybe ("Unknown DatabaseUrlStorage:" ++ v))
