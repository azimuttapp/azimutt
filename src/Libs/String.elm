module Libs.String exposing (hashCode, plural, pluralize, unique, wordSplit)

import Bitwise
import Libs.Maybe as M
import Libs.Regex as R


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
