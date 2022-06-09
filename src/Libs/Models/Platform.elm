module Libs.Models.Platform exposing (Platform(..), fromString)


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
