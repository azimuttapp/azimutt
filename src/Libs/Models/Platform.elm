module Libs.Models.Platform exposing (Platform(..), fromString, toString)


type Platform
    = PC
    | Mac


fromString : String -> Platform
fromString value =
    case value of
        "pc" ->
            PC

        "mac" ->
            Mac

        _ ->
            PC


toString : Platform -> String
toString value =
    case value of
        PC ->
            "pc"

        Mac ->
            "mac"
