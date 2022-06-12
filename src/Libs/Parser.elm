module Libs.Parser exposing (deadEndToString)

import Parser exposing (DeadEnd, Problem(..))


deadEndToString : DeadEnd -> String
deadEndToString err =
    "error at line " ++ String.fromInt err.row ++ ":" ++ String.fromInt err.col ++ ": " ++ problemToString err.problem


problemToString : Problem -> String
problemToString problem =
    case problem of
        Expecting token ->
            "Expecting " ++ token

        ExpectingInt ->
            "ExpectingInt"

        ExpectingHex ->
            "ExpectingHex"

        ExpectingOctal ->
            "ExpectingOctal"

        ExpectingBinary ->
            "ExpectingBinary"

        ExpectingFloat ->
            "ExpectingFloat"

        ExpectingNumber ->
            "ExpectingNumber"

        ExpectingVariable ->
            "ExpectingVariable"

        ExpectingSymbol symbol ->
            "ExpectingSymbol " ++ symbol

        ExpectingKeyword keywork ->
            "ExpectingKeyword " ++ keywork

        ExpectingEnd ->
            "ExpectingEnd"

        UnexpectedChar ->
            "UnexpectedChar"

        Problem err ->
            "Problem " ++ err

        BadRepeat ->
            "BadRepeat"
