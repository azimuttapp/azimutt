module Libs.Regex exposing (matches)

import Regex


matches : String -> String -> List (Maybe String)
matches regex text =
    Regex.fromStringWith { caseInsensitive = True, multiline = False } regex
        |> Maybe.withDefault Regex.never
        |> (\r -> Regex.find r text)
        |> List.concatMap .submatches
