module Models.Project.ProjectStorage exposing (ProjectStorage(..), decode, encode, fromString, toString)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Maybe as Maybe


type ProjectStorage
    = Local
    | Remote


toString : ProjectStorage -> String
toString value =
    case value of
        Local ->
            "local"

        Remote ->
            "remote"


fromString : String -> Maybe ProjectStorage
fromString value =
    case value of
        "local" ->
            Just Local

        "remote" ->
            Just Remote

        -- legacy values:
        "browser" ->
            Just Local

        "cloud" ->
            Just Remote

        _ ->
            Nothing


encode : ProjectStorage -> Value
encode value =
    value |> toString |> Encode.string


decode : Decode.Decoder ProjectStorage
decode =
    Decode.string
        |> Decode.andThen (\v -> v |> fromString |> Maybe.mapOrElse Decode.succeed (Decode.fail ("invalid ProjectStorage '" ++ v ++ "'")))
