module Libs.Basics exposing (convertBase, fromDec, inside, maxBy, minBy, percent, prettyNumber, toDec, toHex, toOct, tupled)

import Array exposing (Array)
import Dict exposing (Dict)
import Libs.Maybe as Maybe
import Round


convertBase : Int -> Int -> String -> Result (List String) String
convertBase fromBase toBase value =
    let
        dict : Array Char
        dict =
            "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" |> String.toList |> Array.fromList

        fromDict : Dict Char Int
        fromDict =
            dict |> Array.slice 0 fromBase |> Array.toIndexedList |> List.map (\( i, c ) -> ( c, i )) |> Dict.fromList

        toDict : Dict Int Char
        toDict =
            dict |> Array.slice 0 toBase |> Array.toIndexedList |> Dict.fromList
    in
    (fromBase |> checkBase dict)
        |> Result.andThen (\_ -> toBase |> checkBase dict)
        |> Result.map (\_ -> value)
        |> Result.map removeSign
        |> Result.andThen (toDecInner fromBase fromDict)
        |> Result.map (fromDecInner toBase toDict "")
        |> Result.map (addSign value)


toDec : Int -> String -> Result (List String) Int
toDec fromBase value =
    value |> convertBase fromBase 10 |> Result.andThen (\r -> String.toInt r |> Result.fromMaybe [ "Can't convert " ++ r ++ " to Int" ])


fromDec : Int -> Int -> Result (List String) String
fromDec toBase value =
    value |> String.fromInt |> convertBase 10 toBase


toOct : Int -> String
toOct value =
    value |> fromDec 8 |> Result.withDefault ""


toHex : Int -> String
toHex value =
    value |> fromDec 16 |> Result.withDefault ""


percent : Int -> Int -> Float
percent total value =
    100 * toFloat value / toFloat total


prettyNumber : Float -> String
prettyNumber value =
    if value == 0 then
        "0"

    else if value > 10 then
        value |> Round.round 0

    else if value > 1 then
        value |> Round.round 1

    else
        value |> Round.round 2


maxBy : (a -> comparable) -> a -> a -> a
maxBy getKey x y =
    if getKey x > getKey y then
        x

    else
        y


minBy : (a -> comparable) -> a -> a -> a
minBy getKey x y =
    if getKey x < getKey y then
        x

    else
        y


checkBase : Array Char -> Int -> Result (List String) ()
checkBase dict base =
    if base < 2 then
        Err [ "Base " ++ String.fromInt base ++ " is not valid" ]

    else if base > Array.length dict then
        Err [ "Base " ++ String.fromInt base ++ " is too big, max is " ++ String.fromInt (Array.length dict) ]

    else
        Ok ()


removeSign : String -> String
removeSign value =
    if value |> String.startsWith "-" then
        value |> String.dropLeft 1

    else
        value


addSign : String -> String -> String
addSign initValue value =
    if initValue |> String.startsWith "-" then
        "-" ++ value

    else
        value


toDecInner : Int -> Dict Char Int -> String -> Result (List String) Int
toDecInner base dict value =
    value
        |> String.toList
        |> List.indexedMap (\i c -> ( c, dict |> Dict.get c, String.length value - 1 - i ))
        |> List.foldr
            (\( digit, digitValue, index ) acc ->
                case ( digitValue, acc ) of
                    ( Just v, Ok cur ) ->
                        Ok (cur + (v * (base ^ index)))

                    ( Just _, err ) ->
                        err

                    ( Nothing, Ok _ ) ->
                        Err [ errorMsg base digit ]

                    ( Nothing, Err errs ) ->
                        Err (errorMsg base digit :: errs)
            )
            (Ok 0)


errorMsg : Int -> Char -> String
errorMsg base digit =
    "Invalid digit '" ++ String.fromChar digit ++ "' for base " ++ String.fromInt base


fromDecInner : Int -> Dict Int Char -> String -> Int -> String
fromDecInner base dict suffix value =
    if value > 0 then
        value
            |> modBy base
            |> (\index ->
                    dict
                        |> Dict.get index
                        |> Maybe.mapOrElse
                            (\c ->
                                fromDecInner base
                                    dict
                                    (String.fromChar c ++ suffix)
                                    ((value - index) // base)
                            )
                            suffix
               )

    else if suffix == "" then
        dict |> Dict.get 0 |> Maybe.mapOrElse String.fromChar suffix

    else
        suffix


inside : comparable -> comparable -> comparable -> comparable
inside minValue maxValue value =
    value |> min maxValue |> max minValue


tupled : (a -> b -> c) -> (( a, b ) -> c)
tupled f ( a, b ) =
    f a b
