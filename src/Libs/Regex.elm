module Libs.Regex exposing (match, matches, replace)

import Regex exposing (Regex)


matches : String -> String -> List (Maybe String)
matches regex text =
    regex |> asRegex |> (\r -> Regex.find r text) |> List.concatMap .submatches


match : String -> String -> Bool
match regex text =
    regex |> asRegex |> (\r -> Regex.contains r text)


replace : String -> String -> String -> String
replace fromRegex to text =
    fromRegex |> asRegex |> (\r -> Regex.replace r (\_ -> to) text)


asRegex : String -> Regex
asRegex regex =
    Regex.fromStringWith { caseInsensitive = True, multiline = False } regex
        |> Maybe.withDefault Regex.never
