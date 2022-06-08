module Libs.Regex exposing (asRegexI, match, matchI, matches, replace)

import Regex exposing (Regex)


matches : String -> String -> List (Maybe String)
matches regex text =
    regex |> asRegexI |> (\r -> Regex.find r text) |> List.concatMap .submatches


matchI : String -> String -> Bool
matchI regex text =
    regex |> asRegexI |> (\r -> Regex.contains r text)


match : String -> String -> Bool
match regex text =
    regex |> asRegex |> (\r -> Regex.contains r text)


replace : String -> String -> String -> String
replace fromRegex to text =
    fromRegex |> asRegexI |> (\r -> Regex.replace r (\_ -> to) text)


asRegexI : String -> Regex
asRegexI regex =
    Regex.fromStringWith { caseInsensitive = True, multiline = False } regex
        |> Maybe.withDefault Regex.never


asRegex : String -> Regex
asRegex regex =
    Regex.fromStringWith { caseInsensitive = False, multiline = False } regex
        |> Maybe.withDefault Regex.never
