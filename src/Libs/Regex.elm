module Libs.Regex exposing (contains, matches)

import Regex exposing (Regex)


matches : String -> String -> List (Maybe String)
matches regex text =
    regex |> asRegex |> (\r -> Regex.find r text) |> List.concatMap .submatches


contains : String -> String -> Bool
contains regex text =
    regex |> asRegex |> (\r -> Regex.contains r text)


asRegex : String -> Regex
asRegex regex =
    Regex.fromStringWith { caseInsensitive = True, multiline = False } regex
        |> Maybe.withDefault Regex.never
