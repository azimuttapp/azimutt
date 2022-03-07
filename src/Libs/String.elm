module Libs.String exposing (filterStartsWith, hashCode, inflect, nonEmpty, orElse, plural, pluralize, pluralizeD, pluralizeL, unique, wordSplit)

import Bitwise
import Dict exposing (Dict)
import Libs.Maybe as Maybe
import Libs.Regex as Regex


nonEmpty : String -> Bool
nonEmpty string =
    string /= ""


orElse : String -> String -> String
orElse other str =
    if str == "" then
        other

    else
        str


filterStartsWith : String -> String -> String
filterStartsWith prefix str =
    if str |> String.startsWith prefix then
        str

    else
        ""


wordSplit : String -> List String
wordSplit input =
    List.foldl (\sep words -> words |> List.concatMap (\word -> String.split sep word)) [ input ] [ "_", "-", " " ]


hashCode : String -> Int
hashCode input =
    String.foldl updateHash 5381 input


updateHash : Char -> Int -> Int
updateHash char code =
    Bitwise.shiftLeftBy code (5 + code + Char.toCode char)


unique : List String -> String -> String
unique takenIds id =
    if takenIds |> List.any (\taken -> taken == id) then
        case id |> Regex.matches "^(.*?)([0-9]+)?(\\.[a-z]+)?$" of
            (Just prefix) :: num :: extension :: [] ->
                unique
                    takenIds
                    (prefix
                        ++ (num |> Maybe.andThen String.toInt |> Maybe.mapOrElse (\n -> n + 1) 2 |> String.fromInt)
                        ++ (extension |> Maybe.withDefault "")
                    )

            _ ->
                id ++ "-err"

    else
        id


inflect : String -> String -> String -> Int -> String
inflect none one many count =
    if count == 0 then
        none

    else if count == 1 then
        one

    else
        many


plural : String -> String
plural word =
    -- trivial pluralize that works only for usual words, use `inflect` for more flexibility
    if word |> String.endsWith "y" then
        (word |> String.dropRight 1) ++ "ies"

    else
        word ++ "s"


pluralize : String -> Int -> String
pluralize word count =
    count |> inflect ("0 " ++ word) ("1 " ++ word) (String.fromInt count ++ " " ++ plural word)


pluralizeL : String -> List a -> String
pluralizeL word list =
    list |> List.length |> pluralize word


pluralizeD : String -> Dict k a -> String
pluralizeD word list =
    list |> Dict.size |> pluralize word
