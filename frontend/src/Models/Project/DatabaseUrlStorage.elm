module Models.Project.DatabaseUrlStorage exposing (DatabaseUrlStorage(..), decode, encode, fromString, toString)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode


type DatabaseUrlStorage
    = Project
    | Browser
    | None


toString : DatabaseUrlStorage -> String
toString kind =
    case kind of
        Project ->
            "project"

        Browser ->
            "browser"

        None ->
            "none"


fromString : String -> Maybe DatabaseUrlStorage
fromString kind =
    case kind of
        "project" ->
            Just Project

        "browser" ->
            Just Browser

        "none" ->
            Just None

        _ ->
            Nothing


encode : DatabaseUrlStorage -> Value
encode value =
    value |> toString |> Encode.string


decode : Decoder DatabaseUrlStorage
decode =
    Decode.string |> Decode.andThen (\v -> v |> fromString |> Decode.fromMaybe ("Unknown DatabaseUrlStorage:" ++ v))
