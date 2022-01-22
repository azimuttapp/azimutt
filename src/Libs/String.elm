module Libs.String exposing (filterStartsWith, hashCode, plural, pluralize, pluralizeD, pluralizeL, unique, wordSplit)

import Bitwise
import Dict exposing (Dict)
import Libs.Maybe as M
import Libs.Regex as R


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
        case id |> R.matches "^(.*?)([0-9]+)?(\\.[a-z]+)?$" of
            (Just prefix) :: num :: extension :: [] ->
                unique
                    takenIds
                    (prefix
                        ++ (num |> Maybe.andThen String.toInt |> M.mapOrElse (\n -> n + 1) 2 |> String.fromInt)
                        ++ (extension |> Maybe.withDefault "")
                    )

            _ ->
                id ++ "-err"

    else
        id


plural : String -> String -> String -> Int -> String
plural none one many count =
    if count == 0 then
        none

    else if count == 1 then
        one

    else
        String.fromInt count ++ " " ++ many


pluralize : String -> Int -> String
pluralize word =
    -- trivial pluralize that works only for "regular" words, use `plural` for more flexibility
    plural ("0 " ++ word) ("1 " ++ word) (word ++ "s")


pluralizeL : String -> List a -> String
pluralizeL word list =
    list |> List.length |> pluralize word


pluralizeD : String -> Dict k a -> String
pluralizeD word list =
    list |> Dict.size |> pluralize word
