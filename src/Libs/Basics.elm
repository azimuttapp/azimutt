module Libs.Basics exposing (convertBase, fromDec, toDec, toHex, toOct)

import Array exposing (Array)
import Dict exposing (Dict)
import Libs.Nel as Nel exposing (Nel)


convertBase : Int -> Int -> String -> Result (Nel String) String
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


toDec : Int -> String -> Result (Nel String) Int
toDec fromBase value =
    value |> convertBase fromBase 10 |> Result.andThen (\r -> String.toInt r |> Result.fromMaybe (Nel ("Can't convert " ++ r ++ " to Int") []))


fromDec : Int -> Int -> Result (Nel String) String
fromDec toBase value =
    value |> String.fromInt |> convertBase 10 toBase


toOct : Int -> String
toOct value =
    value |> fromDec 8 |> Result.withDefault ""


toHex : Int -> String
toHex value =
    value |> fromDec 16 |> Result.withDefault ""


checkBase : Array Char -> Int -> Result (Nel String) ()
checkBase dict base =
    if base < 2 then
        Err (Nel ("Base " ++ String.fromInt base ++ " is not valid") [])

    else if base > Array.length dict then
        Err (Nel ("Base " ++ String.fromInt base ++ " is too big, max is " ++ String.fromInt (Array.length dict)) [])

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


toDecInner : Int -> Dict Char Int -> String -> Result (Nel String) Int
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
                        Err (Nel (errorMsg base digit) [])

                    ( Nothing, Err errs ) ->
                        Err (errs |> Nel.prepend (errorMsg base digit))
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
                        |> Maybe.map
                            (\c ->
                                fromDecInner base
                                    dict
                                    (String.fromChar c ++ suffix)
                                    ((value - index) // base)
                            )
                        |> Maybe.withDefault suffix
               )

    else if suffix == "" then
        dict |> Dict.get 0 |> Maybe.map String.fromChar |> Maybe.withDefault suffix

    else
        suffix
