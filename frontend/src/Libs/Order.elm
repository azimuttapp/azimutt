module Libs.Order exposing (compareBool, compareDict, compareList, compareMaybe, dir, reverse)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe


reverse : Order -> Order
reverse o =
    case o of
        LT ->
            GT

        GT ->
            LT

        EQ ->
            EQ


dir : Bool -> Order -> Order
dir asc o =
    if asc then
        o

    else
        reverse o


compareBool : Bool -> Bool -> Order
compareBool b2 b1 =
    if b2 == b1 then
        EQ

    else if b1 == True then
        LT

    else
        GT


compareList : (a -> a -> Order) -> List a -> List a -> Order
compareList compare list2 list1 =
    list1 |> List.zip list2 |> List.find (\( v1, v2 ) -> compare v1 v2 /= EQ) |> Maybe.mapOrElse (\( v1, v2 ) -> compare v1 v2) EQ


compareDict : (a -> a -> Order) -> Dict comparable a -> Dict comparable a -> Order
compareDict compare dict1 dict2 =
    dict1 |> Dict.zip dict2 |> Dict.find (\_ ( v1, v2 ) -> compare v1 v2 /= EQ) |> Maybe.mapOrElse (\( _, ( v1, v2 ) ) -> compare v1 v2) EQ


compareMaybe : (a -> a -> Order) -> Maybe a -> Maybe a -> Order
compareMaybe compare maybe1 maybe2 =
    case ( maybe1, maybe2 ) of
        ( Just v1, Just v2 ) ->
            compare v1 v2

        ( Just _, Nothing ) ->
            GT

        ( Nothing, Just _ ) ->
            LT

        ( Nothing, Nothing ) ->
            EQ
